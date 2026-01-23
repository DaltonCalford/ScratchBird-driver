require "socket"
require "openssl"

require "scratchbird/config"
require "scratchbird/errors"
require "scratchbird/protocol"
require "scratchbird/result"
require "scratchbird/scram"
require "scratchbird/sql"
require "scratchbird/types"

module Scratchbird
  class Client
    QUERY_FLAG_BINARY_RESULT = 0x04

    attr_reader :parameters

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
    end

    def connect
      raise ConnectionError, "user and database are required" if @config.user.to_s.empty? || @config.database.to_s.empty?
      raw_socket = connect_tcp
      @socket = wrap_tls(raw_socket)
      handshake
      @connected = true
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
      end
    end

    def disconnect
      close
    end

    def begin_transaction
      ensure_connected
    end

    def commit
      ensure_connected
      execute_simple("COMMIT")
    end

    def rollback
      ensure_connected
      execute_simple("ROLLBACK")
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
      send_message(Protocol::MSG_SYNC, +"", 0, false)
      drain_until_ready
      @prepared[name] = normalized.sql
    end

    def execute(name, params = nil, options = nil)
      ensure_connected
      sql = @prepared[name]
      raise ArgumentError, "unknown prepared statement: #{name}" unless sql
      normalized = Sql.normalize(sql, params)
      execute_prepared(name, normalized.params, options)
    end

    def execute_stream(name, params = nil, options = nil)
      ensure_connected
      sql = @prepared[name]
      raise ArgumentError, "unknown prepared statement: #{name}" unless sql
      normalized = Sql.normalize(sql, params)
      execute_prepared_stream(name, normalized.params, options)
    end

    def cancel
      payload = Protocol.build_cancel_payload(0, @last_query_sequence)
      send_message(Protocol::MSG_CANCEL, payload, Protocol::MSG_FLAG_URGENT, false)
    end

    def update_txn_id(txn_id)
      @txn_id = txn_id
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
        ctx.key = OpenSSL::PKey.read(File.read(@config.sslkey))
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

    def handshake
      features = 0
      features |= Protocol::FEATURE_COMPRESSION if @config.compression.to_s.downcase == "zstd"
      features |= Protocol::FEATURE_STREAMING if @config.binary_transfer
      params = { "database" => @config.database, "user" => @config.user }
      params["application_name"] = @config.application_name if @config.application_name.to_s != ""
      startup = Protocol.build_startup_payload(features, params)
      send_message(Protocol::MSG_STARTUP, startup, 0, true)

      scram = nil

      loop do
        type, _flags, payload, _sequence, attachment_id, txn_id = recv_message
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

    def execute_query(sql, params, options)
      if params.empty?
        send_simple_query(sql, options)
      else
        send_extended_query(sql, params, options)
      end
      execute_query_loop
    end

    def execute_prepared(name, params, options)
      send_bind_execute(name, params, options)
      execute_query_loop
    end

    def execute_query_stream(sql, params, options)
      if params.empty?
        send_simple_query(sql, options)
      else
        send_extended_query(sql, params, options)
      end
      ResultStream.new(self)
    end

    def execute_prepared_stream(name, params, options)
      send_bind_execute(name, params, options)
      ResultStream.new(self)
    end

    def execute_query_loop
      columns = []
      rows = []
      rowcount = -1
      command_tag = ""

      loop do
        type, _flags, payload, _sequence, _attachment_id, _txn_id = recv_message
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
        when Protocol::MSG_PARAMETER_STATUS
          name, value = Protocol.parse_parameter_status(payload)
          @parameters[name] = value
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
      max_rows = options && options[:max_rows] ? options[:max_rows].to_i : 0
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

      result_formats = @config.binary_transfer ? [Types::FORMAT_BINARY] : []
      bind_payload = Protocol.build_bind_payload("", "", param_values, result_formats)
      send_message(Protocol::MSG_BIND, bind_payload, 0, false)

      max_rows = options && options[:max_rows] ? options[:max_rows].to_i : 0
      exec_payload = Protocol.build_execute_payload("", max_rows)
      @last_query_sequence = send_message(Protocol::MSG_EXECUTE, exec_payload, 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false)
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
      exec_payload = Protocol.build_execute_payload("", max_rows)
      @last_query_sequence = send_message(Protocol::MSG_EXECUTE, exec_payload, 0, false)
      send_message(Protocol::MSG_SYNC, +"", 0, false)
    end

    def execute_simple(sql)
      send_simple_query(sql, nil)
      drain_until_ready
      true
    rescue StandardError
      false
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
        when Protocol::MSG_PARAMETER_STATUS
          name, value = Protocol.parse_parameter_status(payload)
          @client.parameters[name] = value
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
