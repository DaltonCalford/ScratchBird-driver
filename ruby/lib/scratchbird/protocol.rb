module Scratchbird
  module Protocol
    MAGIC = 0x42444253
    VERSION = 0x0100
    MAX_MESSAGE_SIZE = 16 * 1024 * 1024

    MSG_CONNECT_REQUEST = 0x01
    MSG_CONNECT_RESPONSE = 0x02
    MSG_DISCONNECT = 0x03
    MSG_AUTH_REQUEST = 0x10
    MSG_AUTH_RESPONSE = 0x11
    MSG_QUERY = 0x20
    MSG_QUERY_RESULT = 0x21
    MSG_QUERY_ERROR = 0x22
    MSG_QUERY_CANCEL = 0x23
    MSG_PREPARE = 0x30
    MSG_PREPARE_RESPONSE = 0x31
    MSG_EXECUTE = 0x32
    MSG_CLOSE_STATEMENT = 0x33
    MSG_DESCRIBE = 0x34
    MSG_DESCRIBE_RESPONSE = 0x35
    MSG_BEGIN = 0x40
    MSG_COMMIT = 0x41
    MSG_ROLLBACK = 0x42
    MSG_ROW_DESCRIPTION = 0x50
    MSG_ROW_DATA = 0x51
    MSG_END_RESULTS = 0x52
    MSG_COMMAND_COMPLETE = 0x53

    AUTH_SCRAM_SHA256 = 2

    def self.encode_message(type, payload, flags = 0)
      header = [MAGIC, VERSION, type, flags, payload.bytesize].pack("VvCCV")
      header + payload
    end

    def self.decode_header(data)
      raise "Invalid header length" unless data.bytesize == 12
      magic, _version, type, flags, length = data.unpack("VvCCV")
      raise "Invalid protocol magic" unless magic == MAGIC
      raise "Payload too large" if length > MAX_MESSAGE_SIZE
      [type, flags, length]
    end

    def self.build_connect_request(database, client_name, pid)
      payload = [VERSION, 0, pid].pack("vvV")
      payload << write_null(database, 256)
      payload << write_null(client_name, 64)
      payload << write_null("1.0.0", 32)
      encode_message(MSG_CONNECT_REQUEST, payload)
    end

    def self.parse_connect_response(payload)
      raise "Connect response truncated" if payload.bytesize < 1 + 2 + 2 + 16 + 64 + 32
      offset = 0
      status = payload.getbyte(offset)
      offset += 1
      _version = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      offset += 2
      session_id = payload.byteslice(offset, 16)
      offset += 16
      server_name = read_null(payload.byteslice(offset, 64))
      offset += 64
      server_version = read_null(payload.byteslice(offset, 32))
      offset += 32
      error_msg = ""
      if status != 0 && offset + 2 <= payload.bytesize
        msg_len = payload.byteslice(offset, 2).unpack1("v")
        offset += 2
        error_msg = payload.byteslice(offset, msg_len).to_s
      end
      [status == 0, session_id, server_name, server_version, error_msg]
    end

    def self.build_auth_request(session_id, username, method, payload)
      raise "sessionId must be 16 bytes" unless session_id.bytesize == 16
      buffer = session_id.dup
      buffer << write_null(username, 64)
      buffer << [method].pack("C")
      buffer << [payload.bytesize].pack("v")
      buffer << payload
      encode_message(MSG_AUTH_REQUEST, buffer)
    end

    def self.parse_auth_response(payload)
      raise "Auth response truncated" if payload.bytesize < 1 + 4 + 256
      status = payload.getbyte(0)
      user_id = payload.byteslice(1, 4).unpack1("V")
      error_msg = read_null(payload.byteslice(5, 256))
      extra = payload.byteslice(5 + 256, payload.bytesize - (5 + 256))
      [status, user_id, error_msg, extra || ""]
    end

    def self.build_query(session_id, sql, flags = 0)
      raise "sessionId must be 16 bytes" unless session_id.bytesize == 16
      sql_bytes = sql.to_s.b
      payload = session_id.dup
      payload << [sql_bytes.bytesize].pack("V")
      payload << [flags].pack("C")
      payload << sql_bytes
      encode_message(MSG_QUERY, payload)
    end

    def self.parse_row_description(payload)
      raise "Row description truncated" if payload.bytesize < 2
      offset = 0
      count = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      columns = []
      count.times do
        name_len = payload.byteslice(offset, 2).unpack1("v")
        offset += 2
        name = payload.byteslice(offset, name_len).to_s
        offset += name_len
        wire_type = payload.getbyte(offset)
        offset += 1
        modifier = payload.byteslice(offset, 4).unpack1("V")
        offset += 4
        format = payload.byteslice(offset, 2).unpack1("v")
        offset += 2
        columns << { name: name, wire_type: wire_type, type_modifier: modifier, format: format }
      end
      columns
    end

    def self.parse_row_data(payload)
      raise "Row data truncated" if payload.bytesize < 2
      offset = 0
      count = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      values = []
      count.times do
        length = payload.byteslice(offset, 4).unpack1("V")
        offset += 4
        if length & 0x80000000 != 0
          values << { data: nil }
          next
        end
        data = payload.byteslice(offset, length)
        offset += length
        values << { data: data }
      end
      values
    end

    def self.parse_command_complete(payload)
      raise "Command complete truncated" if payload.bytesize < 64 + 8
      tag = read_null(payload.byteslice(0, 64))
      rows = payload.byteslice(64, 8).unpack1("Q<")
      [tag, rows]
    end

    def self.parse_query_result(payload)
      raise "Query result truncated" if payload.bytesize < 1 + 4 + 8
      status = payload.getbyte(0)
      count = payload.byteslice(1, 4).unpack1("V")
      rows = payload.byteslice(5, 8).unpack1("Q<")
      [status, count, rows]
    end

    def self.parse_query_error(payload)
      raise "Query error truncated" if payload.bytesize < 4 + 6 + 2 + 2 + 2
      offset = 0
      code = payload.byteslice(offset, 4).unpack1("V")
      offset += 4
      sqlstate = read_null(payload.byteslice(offset, 6))
      offset += 6
      msg_len = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      detail_len = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      hint_len = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      message = payload.byteslice(offset, msg_len).to_s
      offset += msg_len
      detail = payload.byteslice(offset, detail_len).to_s
      offset += detail_len
      hint = payload.byteslice(offset, hint_len).to_s
      [code, sqlstate, message, detail, hint]
    end

    def self.build_begin(session_id, isolation = 0, read_only = false)
      payload = session_id.dup
      payload << [isolation, read_only ? 1 : 0].pack("CC")
      encode_message(MSG_BEGIN, payload)
    end

    def self.build_commit(session_id)
      encode_message(MSG_COMMIT, session_id)
    end

    def self.build_rollback(session_id)
      encode_message(MSG_ROLLBACK, session_id)
    end

    def self.build_disconnect(session_id)
      encode_message(MSG_DISCONNECT, session_id)
    end

    def self.write_null(value, length)
      data = value.to_s.b
      data = data.byteslice(0, length - 1) if data.bytesize >= length
      data.ljust(length, "\0")
    end

    def self.read_null(data)
      idx = data.index("\0") || data.bytesize
      data.byteslice(0, idx).to_s
    end
  end
end
