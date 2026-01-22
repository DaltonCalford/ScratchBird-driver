require "socket"
require "openssl"

require "scratchbird/config"
require "scratchbird/errors"
require "scratchbird/protocol"
require "scratchbird/result"
require "scratchbird/scram"
require "scratchbird/types"

module Scratchbird
  class Client
    AUTH_STATUS_OK = 0
    AUTH_STATUS_ERROR = 1
    AUTH_STATUS_CONTINUE = 2

    attr_reader :session_id, :server_name, :server_version

    def initialize(config)
      @config = config
      @socket = nil
      @session_id = nil
      @server_name = nil
      @server_version = nil
      @connected = false
      @in_transaction = false
      @socket_timeout = config.socket_timeout_ms.to_i
    end

    def connect
      raise ConnectionError, "user and database are required" if @config.user.to_s.empty? || @config.database.to_s.empty?
      raw_socket = connect_tcp
      @socket = wrap_tls(raw_socket)
      handshake
      authenticate
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
        @session_id = nil
        @in_transaction = false
      end
    end

    def disconnect
      return unless @connected && @session_id
      send_message(Protocol.build_disconnect(@session_id))
    rescue IOError, SystemCallError
      nil
    ensure
      close
    end

    def begin_transaction
      return if @in_transaction
      send_message(Protocol.build_begin(@session_id))
      drain_until_complete
      @in_transaction = true
    end

    def commit
      return unless @in_transaction
      send_message(Protocol.build_commit(@session_id))
      drain_until_complete
      @in_transaction = false
    end

    def rollback
      return unless @in_transaction
      send_message(Protocol.build_rollback(@session_id))
      drain_until_complete
      @in_transaction = false
    end

    def query(sql)
      ensure_connected
      send_message(Protocol.build_query(@session_id, sql, 0))
      execute_query_loop
    end

    def stream(sql)
      ensure_connected
      send_message(Protocol.build_query(@session_id, sql, 0))
      ResultStream.new(self)
    end

    def recv_message
      header = read_exact(12)
      type, _flags, length = Protocol.decode_header(header)
      payload = length.positive? ? read_exact(length) : +""
      [type, payload]
    end

    def decode_row(columns, values)
      row = []
      values.each_with_index do |value, idx|
        wire_type = columns[idx] ? columns[idx][:wire_type] : 0
        row << Types.decode(wire_type, value[:data])
      end
      row
    end

    def handle_query_error(payload)
      code, sqlstate, message, detail, hint = Protocol.parse_query_error(payload)
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

    def drain_until_complete
      loop do
        type, payload = recv_message
        if type == Protocol::MSG_QUERY_ERROR
          handle_query_error(payload)
        end
        return if type == Protocol::MSG_COMMAND_COMPLETE || type == Protocol::MSG_END_RESULTS
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
      sslmode = @config.sslmode.to_s.downcase
      return raw_socket if sslmode == "disable"

      ctx = OpenSSL::SSL::SSLContext.new
      require_tls = %w[require verify-ca verify-full].include?(sslmode)
      verify = %w[verify-ca verify-full].include?(sslmode)
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
      if sslmode == "verify-full" && ssl_socket.respond_to?(:post_connection_check)
        ssl_socket.post_connection_check(@config.host)
      end
      ssl_socket
    rescue OpenSSL::SSL::SSLError
      if %w[allow prefer].include?(sslmode)
        raw_socket
      elsif require_tls
        raw_socket.close
        raise
      else
        raw_socket
      end
    end

    def handshake
      send_message(Protocol.build_connect_request(@config.database, @config.application_name, Process.pid))
      type, payload = recv_message
      raise ConnectionError, "unexpected response to CONNECT_REQUEST" unless type == Protocol::MSG_CONNECT_RESPONSE
      success, session_id, server_name, server_version, error_msg = Protocol.parse_connect_response(payload)
      unless success
        raise ConnectionError, error_msg.empty? ? "connect failed" : error_msg
      end
      @session_id = session_id
      @server_name = server_name
      @server_version = server_version
    end

    def authenticate
      scram = Scram.new(@config.user)
      client_first = scram.client_first_message
      request = Protocol.build_auth_request(@session_id, @config.user, Protocol::AUTH_SCRAM_SHA256, client_first)
      send_message(request)
      type, payload = recv_message
      raise AuthError, "unexpected response to AUTH_REQUEST" unless type == Protocol::MSG_AUTH_RESPONSE
      status, _user_id, error_msg, extra = Protocol.parse_auth_response(payload)
      if status != AUTH_STATUS_CONTINUE
        raise AuthError, error_msg.empty? ? "auth failed" : error_msg
      end
      server_first = extra.to_s
      client_final = scram.handle_server_first(@config.password.to_s, server_first)
      request = Protocol.build_auth_request(@session_id, @config.user, Protocol::AUTH_SCRAM_SHA256, client_final)
      send_message(request)
      type, payload = recv_message
      raise AuthError, "unexpected response to SCRAM final" unless type == Protocol::MSG_AUTH_RESPONSE
      status, _user_id, error_msg, extra = Protocol.parse_auth_response(payload)
      if status != AUTH_STATUS_OK
        raise AuthError, error_msg.empty? ? "auth failed" : error_msg
      end
      scram.verify_server_final(extra.to_s) unless extra.to_s.empty?
    end

    def send_message(data)
      raise ConnectionError, "no active socket" unless @socket
      total = 0
      while total < data.bytesize
        written = @socket.write(data.byteslice(total, data.bytesize - total))
        raise ConnectionError, "socket closed" if written.nil? || written.zero?
        total += written
      end
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
      raise ConnectionError, "client is not connected" unless @connected && @session_id
    end

    def execute_query_loop
      columns = []
      rows = []
      rowcount = -1
      rowcount_hint = -1
      command_tag = ""

      loop do
        type, payload = recv_message
        case type
        when Protocol::MSG_QUERY_ERROR
          handle_query_error(payload)
        when Protocol::MSG_QUERY_RESULT
          _status, _count, rowcount_hint = Protocol.parse_query_result(payload)
        when Protocol::MSG_ROW_DESCRIPTION
          columns = Protocol.parse_row_description(payload)
        when Protocol::MSG_ROW_DATA
          values = Protocol.parse_row_data(payload)
          rows << decode_row(columns, values)
        when Protocol::MSG_COMMAND_COMPLETE
          command_tag, rowcount = Protocol.parse_command_complete(payload)
        when Protocol::MSG_END_RESULTS
          break
        end
      end

      rowcount = rowcount_hint if rowcount < 0 && rowcount_hint >= 0
      rowcount = rows.length if rowcount < 0
      Result.new(columns, rows, rowcount, command_tag)
    end
  end

  class ResultStream
    attr_reader :columns, :rowcount, :command_tag

    def initialize(client)
      @client = client
      @columns = []
      @rowcount = -1
      @rowcount_hint = -1
      @command_tag = ""
      @consumed = false
    end

    def each
      return enum_for(:each) unless block_given?
      raise Error, "stream already consumed" if @consumed
      @consumed = true

      loop do
        type, payload = @client.recv_message
        case type
        when Protocol::MSG_QUERY_ERROR
          @client.handle_query_error(payload)
        when Protocol::MSG_QUERY_RESULT
          _status, _count, @rowcount_hint = Protocol.parse_query_result(payload)
        when Protocol::MSG_ROW_DESCRIPTION
          @columns = Protocol.parse_row_description(payload)
        when Protocol::MSG_ROW_DATA
          values = Protocol.parse_row_data(payload)
          yield @client.decode_row(@columns, values)
        when Protocol::MSG_COMMAND_COMPLETE
          @command_tag, @rowcount = Protocol.parse_command_complete(payload)
        when Protocol::MSG_END_RESULTS
          break
        end
      end

      if @rowcount < 0 && @rowcount_hint >= 0
        @rowcount = @rowcount_hint
      end
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
