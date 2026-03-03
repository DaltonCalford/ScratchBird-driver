# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "socket"
require "openssl"

require "scratchbird/config"
require "scratchbird/errors"
require "scratchbird/protocol"
require "scratchbird/result"
require "scratchbird/scram"
require "scratchbird/sql"
require "scratchbird/types"
require "scratchbird/circuit_breaker"
require "scratchbird/keepalive"
require "scratchbird/leak_detector"
require "scratchbird/telemetry"

module Scratchbird
  class Client
    QUERY_FLAG_BINARY_RESULT = 0x04
    MANAGER_PROTOCOL_MAGIC = 0x42444253
    MANAGER_PROTOCOL_VERSION = 0x0101
    MANAGER_HEADER_SIZE = 12
    MANAGER_MAX_PAYLOAD_SIZE = 16 * 1024 * 1024
    MCP_PROTOCOL_VERSION = 0x0100

    MCP_MSG_CONNECT_RESPONSE = 0x02
    MCP_MSG_AUTH_CHALLENGE = 0x12
    MCP_MSG_AUTH_RESPONSE = 0x11
    MCP_MSG_STATUS_RESPONSE = 0x64
    MCP_MSG_HELLO = 0x65
    MCP_MSG_AUTH_START = 0x66
    MCP_MSG_AUTH_CONTINUE = 0x67
    MCP_MSG_DB_CONNECT = 0x69
    MCP_AUTH_METHOD_TOKEN = 4

    attr_reader :parameters, :txn_id

    def initialize(config)
      @config = config
      @socket = nil
      @connected = false
      @attachment_id = "\0" * 16
      @txn_id = 0
      @sequence = 0
      @last_query_sequence = 0
      @parameters = {}
      @prepared = {}
      @socket_timeout = config.socket_timeout_ms.to_i
      @last_max_rows = 0
      @notification_handlers = []
      @last_plan = nil
      @last_sblr = nil
      @connection_id = "conn-#{object_id}"
      @circuit_breaker = CircuitBreaker.new(CircuitBreakerConfig.new, "ruby")
      @telemetry = TelemetryCollector.new
      @keepalive_manager = KeepaliveManager.new
      @keepalive_tracker = nil
      @leak_detector = LeakDetector.new
      @leak_guard = nil
    end

    def connect
      begin
        @config.protocol = Config.normalize_native_protocol(@config.protocol)
        @config.front_door_mode = Config.normalize_front_door_mode(@config.front_door_mode)
      rescue ArgumentError => e
        raise NotSupportedError, e.message
      end
      begin
        raise ConnectionError, "user and database are required" if @config.user.to_s.empty? || @config.database.to_s.empty?
        raise NotSupportedError, "binary_transfer=false is not supported" unless @config.binary_transfer
        raise NotSupportedError, "compression=zstd is not supported" if @config.compression.to_s.downcase == "zstd"
        raw_socket = connect_tcp
        @socket = wrap_tls(raw_socket)
        perform_manager_connect if @config.front_door_mode == "manager_proxy"
        handshake
        apply_schema
        @connected = true
        @keepalive_manager.start
        @keepalive_tracker = @keepalive_manager.register(@connection_id, self) { ping }
        @leak_detector.start
        @leak_guard = @leak_detector.checkout(@connection_id, driver: "ruby")
      rescue StandardError
        close
        raise
      end
    end

    def connected?
      @connected
    end

    def close
      return unless @socket
      begin
        @socket.close
      rescue IOError
        nil
      ensure
        @socket = nil
        @connected = false
        if @keepalive_tracker
          @keepalive_manager.unregister(@connection_id)
          @keepalive_tracker = nil
        end
        @keepalive_manager.stop
        if @leak_guard
          @leak_guard.release
          @leak_guard = nil
        end
        @leak_detector.stop
      end
    end

    def disconnect
      close
    end

    def begin_transaction
      ensure_connected
      payload = Protocol.build_txn_begin_payload(0, 0, 0, Protocol::ISOLATION_READ_COMMITTED, 0, 0, 0, 0)
      send_message(Protocol::MSG_TXN_BEGIN, payload, 0, false)
      drain_until_ready
    end

    def commit
      ensure_connected
      payload = Protocol.build_txn_commit_payload(0)
      send_message(Protocol::MSG_TXN_COMMIT, payload, 0, false)
      drain_until_ready
    end

    def rollback
      ensure_connected
      payload = Protocol.build_txn_rollback_payload(0)
      send_message(Protocol::MSG_TXN_ROLLBACK, payload, 0, false)
      drain_until_ready
    end

    def savepoint(name)
      ensure_connected
      payload = Protocol.build_txn_savepoint_payload(name)
      send_message(Protocol::MSG_TXN_SAVEPOINT, payload, 0, false)
      drain_until_ready
    end

    def release_savepoint(name)
      ensure_connected
      payload = Protocol.build_txn_release_payload(name)
      send_message(Protocol::MSG_TXN_RELEASE, payload, 0, false)
      drain_until_ready
    end

    def rollback_to_savepoint(name)
      ensure_connected
      payload = Protocol.build_txn_rollback_to_payload(name)
      send_message(Protocol::MSG_TXN_ROLLBACK_TO, payload, 0, false)
      drain_until_ready
    end

    def set_option(name, value)
      ensure_connected
      payload = Protocol.build_set_option_payload(name, value)
      send_message(Protocol::MSG_SET_OPTION, payload, 0, false)
      drain_until_ready
    end

    def ping
      ensure_connected
      send_message(Protocol::MSG_PING, +"", 0, false)
      loop do
        type, _flags, payload, _sequence, _attachment_id, _txn_id = recv_message
        next if handle_async_message(type, payload)
        case type
        when Protocol::MSG_PONG
          return true
        when Protocol::MSG_READY
          _status, txn_id = Protocol.parse_ready(payload)
          @txn_id = txn_id
          return true
        when Protocol::MSG_ERROR
          handle_query_error(payload)
        end
      end
    end

    def subscribe(channel, sub_type = Protocol::SUB_TYPE_CHANNEL, filter_expr = "")
      ensure_connected
      payload = Protocol.build_subscribe_payload(sub_type, channel, filter_expr)
      send_message(Protocol::MSG_SUBSCRIBE, payload, 0, false)
      drain_until_ready
    end

    def unsubscribe(channel)
      ensure_connected
      payload = Protocol.build_unsubscribe_payload(channel)
      send_message(Protocol::MSG_UNSUBSCRIBE, payload, 0, false)
      drain_until_ready
    end

    def execute_sblr(hash, bytecode = nil, params = [])
      ensure_connected
      with_resilience("sblr_execute", nil) do
        values = params.map do |param|
          encoded = Types.encode_param(param)
          encoded[:param]
        end
        payload = Protocol.build_sblr_execute_payload(hash, bytecode, values)
        send_message(Protocol::MSG_SBLR_EXECUTE, payload, 0, false)
        send_message(Protocol::MSG_SYNC, +"", 0, false)
        ResultStream.new(self)
      end
    end

    def stream_control(control_type, window_size, timeout_ms)
      ensure_connected
      payload = Protocol.build_stream_control_payload(control_type, window_size, timeout_ms)
      send_message(Protocol::MSG_STREAM_CONTROL, payload, 0, false)
    end

    def attach_create(emulation_mode, db_name)
      ensure_connected
      payload = Protocol.build_attach_create_payload(emulation_mode, db_name)
      send_message(Protocol::MSG_ATTACH_CREATE, payload, 0, false)
      drain_until_ready
    end

    def attach_detach
      ensure_connected
      send_message(Protocol::MSG_ATTACH_DETACH, +"", 0, false)
      drain_until_ready
    end

    def attach_list
      ensure_connected
      send_message(Protocol::MSG_ATTACH_LIST, +"", 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false)
      ResultStream.new(self)
    end

    def on_notification(&block)
      @notification_handlers << block if block
    end

    def last_plan
      @last_plan
    end

    def last_sblr
      @last_sblr
    end

    def query(sql, params = nil, options = nil)
      ensure_connected
      normalized = Sql.normalize(sql, params)
      execute_query(normalized.sql, normalized.params, options)
    end

    def stream(sql, params = nil, options = nil)
      ensure_connected
      normalized = Sql.normalize(sql, params)
      execute_query_stream(normalized.sql, normalized.params, options)
    end

    def prepare(name, sql)
      raise ArgumentError, "name is required" if name.to_s.empty?
      ensure_connected
      normalized = Sql.normalize(sql)
      payload = Protocol.build_parse_payload(name, normalized.sql, [])
      send_message(Protocol::MSG_PARSE, payload, 0, false)
      param_count = describe_statement(name)
      @prepared[name] = { sql: normalized.sql, param_count: param_count }
    end

    def execute(name, params = nil, options = nil)
      ensure_connected
      entry = @prepared[name]
      raise ArgumentError, "unknown prepared statement: #{name}" unless entry
      normalized = Sql.normalize(entry[:sql], params)
      if entry[:param_count].to_i >= 0 && entry[:param_count].to_i != normalized.params.length
        raise Error.new("parameter count mismatch", "07001")
      end
      execute_prepared(name, normalized.params, options)
    end

    def execute_stream(name, params = nil, options = nil)
      ensure_connected
      entry = @prepared[name]
      raise ArgumentError, "unknown prepared statement: #{name}" unless entry
      normalized = Sql.normalize(entry[:sql], params)
      if entry[:param_count].to_i >= 0 && entry[:param_count].to_i != normalized.params.length
        raise Error.new("parameter count mismatch", "07001")
      end
      execute_prepared_stream(name, normalized.params, options)
    end

    def deallocate(name)
      ensure_connected
      statement_name = name.to_s
      raise ArgumentError, "name is required" if statement_name.empty?
      payload = Protocol.build_close_payload(Protocol::DESCRIBE_STATEMENT, statement_name)
      send_message(Protocol::MSG_CLOSE, payload, 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false)
      drain_until_ready
      @prepared.delete(statement_name)
      true
    end

    def cancel
      payload = Protocol.build_cancel_payload(0, @last_query_sequence)
      send_message(Protocol::MSG_CANCEL, payload, Protocol::MSG_FLAG_URGENT, false)
    end

    def update_txn_id(txn_id)
      @txn_id = txn_id
    end

    def in_transaction?
      @txn_id.to_i != 0
    end

    def recv_message
      header = read_exact(Protocol::HEADER_SIZE)
      type, flags, length, sequence, attachment_id, txn_id = Protocol.decode_header(header)
      payload = length.positive? ? read_exact(length) : +""
      [type, flags, payload, sequence, attachment_id, txn_id]
    end

    def decode_row(columns, values)
      row = []
      values.each_with_index do |value, idx|
        col = columns[idx]
        type_oid = col ? col[:type_oid] : 0
        format = col ? col[:format] : Types::FORMAT_BINARY
        row << Types.decode(type_oid, value[:data], format)
      end
      row
    end

    def handle_query_error(payload)
      _severity, sqlstate, message, detail, hint = Protocol.parse_error_message(payload)
      parts = []
      parts << message if message && !message.empty?
      parts << "DETAIL: #{detail}" if detail && !detail.empty?
      parts << "HINT: #{hint}" if hint && !hint.empty?
      text = parts.empty? ? "query failed" : parts.join("\n")
      text = "[#{sqlstate}] #{text}" if sqlstate && !sqlstate.empty?
      raise ErrorMapper.from_sqlstate(sqlstate, text, detail, hint)
    rescue StandardError
      raise Error, "query failed"
    end

    def drain_until_ready
      loop do
        type, _flags, payload, _sequence, _attachment_id, _txn_id = recv_message
        if handle_async_message(type, payload)
          next
        end
        if type == Protocol::MSG_ERROR
          handle_query_error(payload)
        end
        if type == Protocol::MSG_READY
          _status, txn_id = Protocol.parse_ready(payload)
          @txn_id = txn_id
          return
        end
      end
    end

    private

    def handle_async_message(type, payload)
      case type
      when Protocol::MSG_PARAMETER_STATUS
        name, value = Protocol.parse_parameter_status(payload)
        @parameters[name] = value
        update_attachment_from_param(name, value)
        true
      when Protocol::MSG_NOTIFICATION
        notice = Protocol.parse_notification(payload)
        @notification_handlers.each { |handler| handler.call(notice) }
        true
      when Protocol::MSG_QUERY_PLAN
        @last_plan = Protocol.parse_query_plan(payload)
        true
      when Protocol::MSG_SBLR_COMPILED
        @last_sblr = Protocol.parse_sblr_compiled(payload)
        true
      else
        false
      end
    end

    def update_attachment_from_param(name, value)
      case name
      when "attachment_id"
        parsed = parse_uuid_bytes(value)
        @attachment_id = parsed if parsed
      when "current_txn_id"
        @txn_id = value.to_i
      end
    end

    def parse_uuid_bytes(value)
      hex = value.to_s.delete("-").strip
      return nil unless hex.match?(/\A[0-9a-fA-F]{32}\z/)
      [hex].pack("H*")
    end

    def connect_tcp
      timeout = @config.connect_timeout_ms.to_i / 1000.0
      socket = Socket.tcp(@config.host, @config.port, connect_timeout: timeout)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      socket
    end

    def wrap_tls(raw_socket)
      mode = @config.sslmode.to_s.downcase
      raise ConnectionError, "TLS is required for ScratchBird connections" if mode == "disable"

      ctx = OpenSSL::SSL::SSLContext.new
      if ctx.respond_to?(:min_version=) && defined?(OpenSSL::SSL::TLS1_3_VERSION)
        ctx.min_version = OpenSSL::SSL::TLS1_3_VERSION
      end
      verify = %w[verify-full verify-ca require].include?(mode)
      ctx.verify_mode = verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
      ctx.ca_file = @config.sslrootcert if @config.sslrootcert
      if @config.sslcert && @config.sslkey
        ctx.cert = OpenSSL::X509::Certificate.new(File.read(@config.sslcert))
        ctx.key = OpenSSL::PKey.read(File.read(@config.sslkey), @config.sslpassword)
      end

      ssl_socket = OpenSSL::SSL::SSLSocket.new(raw_socket, ctx)
      ssl_socket.sync_close = true
      ssl_socket.hostname = @config.host if ssl_socket.respond_to?(:hostname=)
      ssl_socket.connect
      if mode == "verify-full" && ssl_socket.respond_to?(:post_connection_check)
        ssl_socket.post_connection_check(@config.host)
      end
      ssl_socket
    rescue OpenSSL::SSL::SSLError
      raw_socket.close
      raise
    end

    def manager_lpref(text)
      encoded = text.to_s.b
      [encoded.bytesize].pack("V") + encoded
    end

    def send_manager_frame(type, payload)
      frame = +""
      frame << [MANAGER_PROTOCOL_MAGIC].pack("V")
      frame << [MANAGER_PROTOCOL_VERSION].pack("v")
      frame << [type, 0].pack("C2")
      frame << [payload.bytesize].pack("V")
      frame << payload
      total = 0
      while total < frame.bytesize
        written = @socket.write(frame.byteslice(total, frame.bytesize - total))
        raise ConnectionError, "manager frame write failed" if written.nil? || written.zero?
        total += written
      end
    end

    def recv_manager_frame
      header = read_exact(MANAGER_HEADER_SIZE)
      magic = header.byteslice(0, 4).unpack1("V")
      raise ConnectionError, "manager frame magic mismatch" unless magic == MANAGER_PROTOCOL_MAGIC
      version = header.byteslice(4, 2).unpack1("v")
      raise ConnectionError, "manager frame version mismatch" unless version == MANAGER_PROTOCOL_VERSION
      type = header.getbyte(6)
      length = header.byteslice(8, 4).unpack1("V")
      raise ConnectionError, "manager payload too large" if length > MANAGER_MAX_PAYLOAD_SIZE
      payload = length.positive? ? read_exact(length) : +""
      [type, payload]
    end

    def perform_manager_connect
      token = @config.manager_auth_token.to_s
      raise ConnectionError, "manager_proxy mode requires manager_auth_token" if token.empty?

      manager_user = @config.manager_username.to_s.empty? ? (@config.user.to_s.empty? ? "admin" : @config.user) : @config.manager_username
      manager_database = @config.manager_database.to_s.empty? ? @config.database.to_s : @config.manager_database
      manager_profile = @config.manager_connection_profile.to_s.empty? ? "native_v3" : @config.manager_connection_profile
      manager_intent = @config.manager_client_intent.to_s.empty? ? "native_v3" : @config.manager_client_intent
      manager_flags = @config.manager_client_flags.to_i & 0xFFFF
      auth_fast_path = @config.manager_auth_fast_path != false

      hello = [MCP_PROTOCOL_VERSION, manager_flags].pack("v2")
      send_manager_frame(MCP_MSG_HELLO, hello)
      type, _payload = recv_manager_frame
      raise ConnectionError, "expected MCP hello status response" unless type == MCP_MSG_STATUS_RESPONSE

      auth_start = +""
      auth_start << manager_lpref(manager_user)
      auth_start << [MCP_AUTH_METHOD_TOKEN].pack("C")
      if auth_fast_path
        auth_start << [token.bytesize].pack("V")
        auth_start << token.b
      else
        auth_start << [0].pack("V")
      end
      send_manager_frame(MCP_MSG_AUTH_START, auth_start)
      type, payload = recv_manager_frame
      if type == MCP_MSG_AUTH_CHALLENGE
        auth_continue = [token.bytesize].pack("V") + token.b
        send_manager_frame(MCP_MSG_AUTH_CONTINUE, auth_continue)
        type, payload = recv_manager_frame
      end
      raise ConnectionError, "expected MCP auth response" unless type == MCP_MSG_AUTH_RESPONSE
      raise ConnectionError, "truncated MCP auth response" if payload.bytesize < (1 + 4 + 256)
      if payload.getbyte(0) != 0
        err = payload.byteslice(5, 256).to_s.sub(/\x00+\z/, "")
        raise AuthError, (err.empty? ? "MCP authentication failed" : err)
      end

      db_connect = +"MCP1"
      db_connect << manager_lpref(manager_database)
      db_connect << manager_lpref(manager_profile)
      db_connect << manager_lpref(manager_intent)
      nonce = OpenSSL::Random.random_bytes(16)
      db_connect << [nonce.bytesize].pack("v")
      db_connect << nonce
      send_manager_frame(MCP_MSG_DB_CONNECT, db_connect)
      type, payload = recv_manager_frame
      raise ConnectionError, "expected MCP connect response" unless type == MCP_MSG_CONNECT_RESPONSE
      raise ConnectionError, "truncated MCP connect response" if payload.bytesize < (1 + 2 + 2 + 16 + 64 + 32)
      if payload.getbyte(0) != 0
        err = "MCP database connect failed"
        err_offset = 1 + 2 + 2 + 16 + 64 + 32
        if payload.bytesize >= err_offset + 4
          err_len = payload.byteslice(err_offset, 4).unpack1("V")
          if payload.bytesize >= err_offset + 4 + err_len
            err = payload.byteslice(err_offset + 4, err_len).to_s
          end
        end
        raise AuthError, err
      end
    end

    def handshake
      features = 0
      features |= Protocol::FEATURE_COMPRESSION if @config.compression.to_s.downcase == "zstd"
      features |= Protocol::FEATURE_STREAMING if @config.binary_transfer
      params = { "database" => @config.database, "user" => @config.user }
      params["role"] = @config.role if @config.role.to_s != ""
      params["application_name"] = @config.application_name if @config.application_name.to_s != ""
      startup = Protocol.build_startup_payload(features, params)
      send_message(Protocol::MSG_STARTUP, startup, 0, true)

      scram = nil

      loop do
        type, _flags, payload, _sequence, attachment_id, txn_id = recv_message
        if handle_async_message(type, payload)
          next
        end
        case type
        when Protocol::MSG_NEGOTIATE_VERSION
          next
        when Protocol::MSG_AUTH_REQUEST
          method, data = Protocol.parse_auth_request(payload)
          if method == Protocol::AUTH_OK
            next
          end
          if method == Protocol::AUTH_PASSWORD
            send_message(Protocol::MSG_AUTH_RESPONSE, @config.password.to_s, 0, true)
            next
          end
          if method == Protocol::AUTH_SCRAM_SHA256
            scram ||= Scram.new(@config.user)
            client_first = scram.client_first_message
            send_message(Protocol::MSG_AUTH_RESPONSE, client_first, 0, true)
            next
          end
          raise AuthError, "unsupported auth method"
        when Protocol::MSG_AUTH_CONTINUE
          method, _stage, data = Protocol.parse_auth_continue(payload)
          unless method == Protocol::AUTH_SCRAM_SHA256 && scram
            raise AuthError, "unsupported auth continue"
          end
          client_final = scram.handle_server_first(@config.password.to_s, data.to_s)
          send_message(Protocol::MSG_AUTH_RESPONSE, client_final, 0, true)
          next
        when Protocol::MSG_AUTH_OK
          _session_id, server_info = Protocol.parse_auth_ok(payload)
          @attachment_id = attachment_id
          @txn_id = txn_id
          if scram && server_info.to_s.start_with?("v=")
            scram.verify_server_final(server_info.to_s)
          end
          next
        when Protocol::MSG_PARAMETER_STATUS
          name, value = Protocol.parse_parameter_status(payload)
          @parameters[name] = value
          next
        when Protocol::MSG_READY
          _status, txn_id = Protocol.parse_ready(payload)
          @txn_id = txn_id
          return
        when Protocol::MSG_ERROR
          handle_query_error(payload)
        else
          next
        end
      end
    end

    def apply_schema
      schema = @config.schema.to_s.strip
      return if schema.empty? || schema.casecmp("public").zero?
      statement = build_schema_statement(schema)
      return if statement.empty?
      execute_simple(statement)
    end

    def send_message(type, payload, flags, force_zero)
      raise ConnectionError, "no active socket" unless @socket
      sequence = @sequence
      @sequence += 1
      attachment_id = force_zero ? "\0" * 16 : @attachment_id
      txn_id = force_zero ? 0 : @txn_id
      data = Protocol.encode_message(type, payload, flags, sequence, attachment_id, txn_id)
      total = 0
      while total < data.bytesize
        written = @socket.write(data.byteslice(total, data.bytesize - total))
        raise ConnectionError, "socket closed" if written.nil? || written.zero?
        total += written
      end
      sequence
    end

    def read_exact(size)
      raise ConnectionError, "no active socket" unless @socket
      buffer = +""
      while buffer.bytesize < size
        wait_readable
        chunk = @socket.readpartial(size - buffer.bytesize)
        raise ConnectionError, "connection closed" if chunk.nil? || chunk.empty?
        buffer << chunk
      end
      buffer
    rescue EOFError
      raise ConnectionError, "connection closed"
    end

    def wait_readable
      return if @socket_timeout <= 0
      timeout = @socket_timeout / 1000.0
      ready = IO.select([@socket], nil, nil, timeout)
      raise ConnectionError, "socket timed out" unless ready
    end

    def ensure_connected
      raise ConnectionError, "client is not connected" unless @connected
    end

    def with_resilience(operation, sql = nil)
      raise CircuitBreakerOpenError, "Circuit breaker is OPEN" unless @circuit_breaker.allow_request?
      if @keepalive_tracker && @keepalive_tracker.needs_validation?
        ping
        @keepalive_tracker.mark_active
      end
      span = @telemetry.start_span(operation)
      if span && sql
        span.with_attribute("db.statement", TelemetryCollector.sanitize_query(sql))
      end
      success = false
      begin
        result = yield
        success = true
        @circuit_breaker.record_success
        @keepalive_tracker&.mark_active
        result
      rescue => e
        @circuit_breaker.record_failure
        raise e
      ensure
        @telemetry.end_span(span, success)
      end
    end

    def execute_query(sql, params, options)
      with_resilience("query", sql) do
        if params.empty?
          send_simple_query(sql, options)
        else
          send_extended_query(sql, params, options)
        end
        execute_query_loop
      end
    end

    def execute_prepared(name, params, options)
      with_resilience("execute_prepared", nil) do
        send_bind_execute(name, params, options)
        execute_query_loop
      end
    end

    def execute_query_stream(sql, params, options)
      with_resilience("query_stream", sql) do
        if params.empty?
          send_simple_query(sql, options)
        else
          send_extended_query(sql, params, options)
        end
        ResultStream.new(self)
      end
    end

    def execute_prepared_stream(name, params, options)
      with_resilience("execute_prepared_stream", nil) do
        send_bind_execute(name, params, options)
        ResultStream.new(self)
      end
    end

    def execute_query_loop
      columns = []
      rows = []
      rowcount = -1
      command_tag = ""

      loop do
        type, _flags, payload, _sequence, _attachment_id, _txn_id = recv_message
        if handle_async_message(type, payload)
          next
        end
        case type
        when Protocol::MSG_ERROR
          handle_query_error(payload)
        when Protocol::MSG_ROW_DESCRIPTION
          columns = Protocol.parse_row_description(payload)
        when Protocol::MSG_DATA_ROW
          values = Protocol.parse_data_row(payload)
          rows << decode_row(columns, values)
        when Protocol::MSG_COMMAND_COMPLETE
          _command_type, rows_count, _last_id, tag = Protocol.parse_command_complete(payload)
          command_tag = tag
          rowcount = rows_count
        when Protocol::MSG_PORTAL_SUSPENDED
          resume_portal if @last_max_rows.to_i > 0
        when Protocol::MSG_READY
          _status, txn_id = Protocol.parse_ready(payload)
          @txn_id = txn_id
          break
        else
          next
        end
      end

      rowcount = rows.length if rowcount < 0
      Result.new(columns, rows, rowcount, command_tag)
    end

    def send_simple_query(sql, options)
      flags = @config.binary_transfer ? QUERY_FLAG_BINARY_RESULT : 0
      if options
        flags |= Protocol::QUERY_FLAG_INCLUDE_PLAN if options[:include_plan]
        flags |= Protocol::QUERY_FLAG_RETURN_SBLR if options[:return_sblr]
        flags |= Protocol::QUERY_FLAG_DESCRIBE_ONLY if options[:describe_only]
        flags |= Protocol::QUERY_FLAG_NO_CACHE if options[:no_cache]
      end
      max_rows = options && options[:max_rows] ? options[:max_rows].to_i : 0
      @last_max_rows = max_rows
      timeout_ms = options && options[:timeout_ms] ? options[:timeout_ms].to_i : 0
      payload = Protocol.build_query_payload(sql, flags, max_rows, timeout_ms)
      @last_query_sequence = send_message(Protocol::MSG_QUERY, payload, 0, false)
    end

    def send_extended_query(sql, params, options)
      param_values = []
      param_types = []
      params.each do |param|
        encoded = Types.encode_param(param)
        param_values << encoded[:param]
        param_types << encoded[:oid]
      end
      parse_payload = Protocol.build_parse_payload("", sql, param_types)
      send_message(Protocol::MSG_PARSE, parse_payload, 0, false)
      param_count = describe_statement("")
      if param_count.to_i >= 0 && param_count.to_i != params.length
        raise Error.new("parameter count mismatch", "07001")
      end

      result_formats = @config.binary_transfer ? [Types::FORMAT_BINARY] : []
      bind_payload = Protocol.build_bind_payload("", "", param_values, result_formats)
      send_message(Protocol::MSG_BIND, bind_payload, 0, false)

      max_rows = options && options[:max_rows] ? options[:max_rows].to_i : 0
      @last_max_rows = max_rows
      exec_payload = Protocol.build_execute_payload("", max_rows)
      @last_query_sequence = send_message(Protocol::MSG_EXECUTE, exec_payload, 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false) if max_rows == 0
    end

    def send_bind_execute(statement_name, params, options)
      param_values = []
      params.each do |param|
        encoded = Types.encode_param(param)
        param_values << encoded[:param]
      end
      result_formats = @config.binary_transfer ? [Types::FORMAT_BINARY] : []
      bind_payload = Protocol.build_bind_payload("", statement_name, param_values, result_formats)
      send_message(Protocol::MSG_BIND, bind_payload, 0, false)

      max_rows = options && options[:max_rows] ? options[:max_rows].to_i : 0
      @last_max_rows = max_rows
      exec_payload = Protocol.build_execute_payload("", max_rows)
      @last_query_sequence = send_message(Protocol::MSG_EXECUTE, exec_payload, 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false) if max_rows == 0
    end

    def resume_portal
      exec_payload = Protocol.build_execute_payload("", @last_max_rows.to_i)
      send_message(Protocol::MSG_EXECUTE, exec_payload, 0, false)
    end

    def describe_statement(statement_name)
      payload = Protocol.build_describe_payload("S".ord, statement_name)
      send_message(Protocol::MSG_DESCRIBE, payload, 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false)
      param_count = -1
      loop do
        type, _flags, payload, _sequence, _attachment_id, txn_id = recv_message
        if handle_async_message(type, payload)
          next
        end
        case type
        when Protocol::MSG_PARAMETER_DESCRIPTION
          param_count = Protocol.parse_parameter_description(payload).length
        when Protocol::MSG_ERROR
          handle_query_error(payload)
        when Protocol::MSG_READY
          _status, txn = Protocol.parse_ready(payload)
          @txn_id = txn
          break
        else
          next
        end
      end
      param_count
    end

    def execute_simple(sql)
      send_simple_query(sql, nil)
      drain_until_ready
      true
    rescue StandardError
      false
    end

    def build_schema_statement(schema)
      trimmed = schema.strip
      return "" if trimmed.empty?
      if trimmed.include?(",")
        parts = trimmed.split(",").map(&:strip).reject(&:empty?).map { |part| quote_identifier(part) }
        return "" if parts.empty?
        return "SET SEARCH_PATH TO #{parts.join(", ")}"
      end
      "SET SCHEMA #{quote_identifier(trimmed)}"
    end

    def quote_identifier(name)
      "\"#{name.to_s.gsub('"', '""')}\""
    end
  end

  class ResultStream
    attr_reader :columns, :rowcount, :command_tag

    def initialize(client)
      @client = client
      @columns = []
      @rowcount = -1
      @seen_rows = 0
      @command_tag = ""
      @consumed = false
    end

    def each
      return enum_for(:each) unless block_given?
      raise Error, "stream already consumed" if @consumed
      @consumed = true

      loop do
        type, _flags, payload, _sequence, _attachment_id, _txn_id = @client.recv_message
        next if @client.send(:handle_async_message, type, payload)
        case type
        when Protocol::MSG_ERROR
          @client.handle_query_error(payload)
        when Protocol::MSG_ROW_DESCRIPTION
          @columns = Protocol.parse_row_description(payload)
        when Protocol::MSG_DATA_ROW
          values = Protocol.parse_data_row(payload)
          yield @client.decode_row(@columns, values)
          @seen_rows += 1
        when Protocol::MSG_COMMAND_COMPLETE
          _command_type, rows_count, _last_id, tag = Protocol.parse_command_complete(payload)
          @command_tag = tag
          @rowcount = rows_count
        when Protocol::MSG_PORTAL_SUSPENDED
          @client.resume_portal if @client.instance_variable_get(:@last_max_rows).to_i > 0
        when Protocol::MSG_READY
          _status, txn_id = Protocol.parse_ready(payload)
          @client.update_txn_id(txn_id)
          break
        else
          next
        end
      end

      @rowcount = @seen_rows if @rowcount < 0
    end

    def each_hash
      return enum_for(:each_hash) unless block_given?
      each do |row|
        yield to_hash(row)
      end
    end

    def to_a
      rows = []
      each { |row| rows << row }
      rows
    end

    private

    def to_hash(row)
      data = {}
      @columns.each_with_index do |col, idx|
        key = col[:name] || idx
        data[key] = row[idx]
      end
      data
    end
  end
end
