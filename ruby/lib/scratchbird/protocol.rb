module Scratchbird
  module Protocol
    MAGIC = 0x53425750
    VERSION_MAJOR = 1
    VERSION_MINOR = 1
    HEADER_SIZE = 40
    MAX_MESSAGE_SIZE = 1024 * 1024 * 1024

    MSG_STARTUP = 0x01
    MSG_AUTH_RESPONSE = 0x02
    MSG_QUERY = 0x03
    MSG_PARSE = 0x04
    MSG_BIND = 0x05
    MSG_DESCRIBE = 0x06
    MSG_EXECUTE = 0x07
    MSG_CLOSE = 0x08
    MSG_SYNC = 0x09
    MSG_FLUSH = 0x0A
    MSG_CANCEL = 0x0B
    MSG_COPY_DATA = 0x0D
    MSG_COPY_DONE = 0x0E
    MSG_COPY_FAIL = 0x0F

    MSG_AUTH_REQUEST = 0x40
    MSG_AUTH_OK = 0x41
    MSG_AUTH_CONTINUE = 0x42
    MSG_READY = 0x43
    MSG_ROW_DESCRIPTION = 0x44
    MSG_DATA_ROW = 0x45
    MSG_COMMAND_COMPLETE = 0x46
    MSG_EMPTY_QUERY = 0x47
    MSG_ERROR = 0x48
    MSG_NOTICE = 0x49
    MSG_PARSE_COMPLETE = 0x4A
    MSG_BIND_COMPLETE = 0x4B
    MSG_CLOSE_COMPLETE = 0x4C
    MSG_PORTAL_SUSPENDED = 0x4D
    MSG_NO_DATA = 0x4E
    MSG_PARAMETER_STATUS = 0x4F
    MSG_PARAMETER_DESCRIPTION = 0x50
    MSG_COPY_IN_RESPONSE = 0x51
    MSG_COPY_OUT_RESPONSE = 0x52
    MSG_COPY_BOTH_RESPONSE = 0x53
    MSG_NOTIFICATION = 0x54
    MSG_NEGOTIATE_VERSION = 0x56
    MSG_STREAM_READY = 0x59
    MSG_STREAM_DATA = 0x5A
    MSG_STREAM_END = 0x5B
    MSG_TXN_STATUS = 0x5C
    MSG_PONG = 0x5D

    AUTH_OK = 0
    AUTH_PASSWORD = 1
    AUTH_MD5 = 2
    AUTH_SCRAM_SHA256 = 3
    AUTH_CERTIFICATE = 4
    AUTH_GSSAPI = 5
    AUTH_SSPI = 6
    AUTH_LDAP = 7
    AUTH_SAML = 8
    AUTH_OIDC = 9
    AUTH_MFA_TOTP = 10
    AUTH_CLUSTER_PKI = 11

    MSG_FLAG_COMPRESSED = 0x01
    MSG_FLAG_CONTINUED = 0x02
    MSG_FLAG_FINAL = 0x04
    MSG_FLAG_URGENT = 0x08
    MSG_FLAG_ENCRYPTED = 0x10
    MSG_FLAG_CHECKSUM = 0x20

    FEATURE_COMPRESSION = 1
    FEATURE_STREAMING = 2
    FEATURE_SBLR = 4
    FEATURE_FEDERATION = 8
    FEATURE_NOTIFICATIONS = 16
    FEATURE_QUERY_PLAN = 32
    FEATURE_BATCH = 64
    FEATURE_PIPELINE = 128
    FEATURE_BINARY_COPY = 256
    FEATURE_SAVEPOINTS = 512
    FEATURE_2PC = 1024
    FEATURE_CHECKSUMS = 2048

    def self.encode_message(type, payload, flags, sequence, attachment_id, txn_id)
      header = [MAGIC, VERSION_MAJOR, VERSION_MINOR, type, flags, payload.bytesize, sequence].pack("VCCCCVV")
      header << pad_bytes(attachment_id, 16)
      header << [txn_id].pack("Q<")
      header + payload
    end

    def self.decode_header(data)
      raise "Invalid header length" unless data.bytesize == HEADER_SIZE
      magic, major, minor, type, flags, length, sequence = data.unpack("VCCCCVV")
      raise "Invalid protocol magic" unless magic == MAGIC
      raise "Unsupported protocol version" unless major == VERSION_MAJOR && minor == VERSION_MINOR
      raise "Payload too large" if length > MAX_MESSAGE_SIZE
      attachment_id = data.byteslice(16, 16)
      txn_id = data.byteslice(32, 8).unpack1("Q<")
      [type, flags, length, sequence, attachment_id, txn_id]
    end

    def self.build_startup_payload(features, params)
      payload = [VERSION_MAJOR, VERSION_MINOR, 0].pack("CCv")
      payload << [features].pack("Q<")
      payload << build_param_list(params)
      payload
    end

    def self.build_param_list(params)
      buf = +""
      params.each do |key, value|
        buf << key.to_s << "\0" << value.to_s << "\0"
      end
      buf << "\0"
      buf
    end

    def self.parse_auth_request(payload)
      raise "Auth request truncated" if payload.bytesize < 4
      method = payload.getbyte(0)
      data = payload.byteslice(4, payload.bytesize - 4) || ""
      [method, data]
    end

    def self.parse_auth_continue(payload)
      raise "Auth continue truncated" if payload.bytesize < 8
      method = payload.getbyte(0)
      stage = payload.getbyte(1)
      data_len = payload.byteslice(4, 4).unpack1("V")
      raise "Auth continue truncated" if 8 + data_len > payload.bytesize
      data = payload.byteslice(8, data_len) || ""
      [method, stage, data]
    end

    def self.parse_auth_ok(payload)
      raise "Auth ok truncated" if payload.bytesize < 20
      session_id = payload.byteslice(0, 16)
      info_len = payload.byteslice(16, 4).unpack1("V")
      raise "Auth ok truncated" if 20 + info_len > payload.bytesize
      server_info = payload.byteslice(20, info_len) || ""
      [session_id, server_info]
    end

    def self.build_query_payload(sql, flags, max_rows, timeout_ms)
      [flags, max_rows, timeout_ms].pack("VVV") + sql.to_s + "\0"
    end

    def self.build_parse_payload(statement_name, sql, param_types)
      name_bytes = statement_name.to_s
      sql_bytes = sql.to_s
      payload = [name_bytes.bytesize].pack("V") + name_bytes
      payload << [sql_bytes.bytesize].pack("V") + sql_bytes
      payload << [param_types.length].pack("v")
      payload << [0].pack("v")
      param_types.each { |oid| payload << [oid].pack("V") }
      payload
    end

    def self.build_bind_payload(portal_name, statement_name, params, result_formats)
      portal_bytes = portal_name.to_s
      stmt_bytes = statement_name.to_s
      payload = [portal_bytes.bytesize].pack("V") + portal_bytes
      payload << [stmt_bytes.bytesize].pack("V") + stmt_bytes
      payload << [params.length].pack("v")
      params.each { |param| payload << [param[:format]].pack("v") }
      payload << [params.length].pack("v")
      payload << [0].pack("v")
      params.each do |param|
        if param[:is_null]
          payload << [-1].pack("l<")
        else
          data = param[:data] || ""
          payload << [data.bytesize].pack("l<")
          payload << data
        end
      end
      payload << [result_formats.length].pack("v")
      result_formats.each { |fmt| payload << [fmt].pack("v") }
      payload
    end

    def self.build_execute_payload(portal_name, max_rows)
      portal_bytes = portal_name.to_s
      [portal_bytes.bytesize].pack("V") + portal_bytes + [max_rows].pack("V")
    end

    def self.build_cancel_payload(cancel_type, target_sequence)
      [cancel_type, target_sequence].pack("VV")
    end

    def self.parse_ready(payload)
      raise "Ready truncated" if payload.bytesize < 20
      status = payload.getbyte(0)
      txn_id = payload.byteslice(4, 8).unpack1("Q<")
      visibility = payload.byteslice(12, 8).unpack1("Q<")
      [status, txn_id, visibility]
    end

    def self.parse_parameter_status(payload)
      raise "Parameter status truncated" if payload.bytesize < 8
      offset = 0
      name_len = payload.byteslice(offset, 4).unpack1("V")
      offset += 4
      name = payload.byteslice(offset, name_len).to_s
      offset += name_len
      value_len = payload.byteslice(offset, 4).unpack1("V")
      offset += 4
      value = payload.byteslice(offset, value_len).to_s
      [name, value]
    end

    def self.parse_row_description(payload)
      raise "Row description truncated" if payload.bytesize < 4
      offset = 0
      count = payload.byteslice(offset, 2).unpack1("v")
      offset += 4
      columns = []
      count.times do
        name_len = payload.byteslice(offset, 4).unpack1("V")
        offset += 4
        name = payload.byteslice(offset, name_len).to_s
        offset += name_len
        table_oid = payload.byteslice(offset, 4).unpack1("V")
        offset += 4
        column_index = payload.byteslice(offset, 2).unpack1("v")
        offset += 2
        type_oid = payload.byteslice(offset, 4).unpack1("V")
        offset += 4
        type_size = payload.byteslice(offset, 2).unpack1("s<")
        offset += 2
        type_modifier = payload.byteslice(offset, 4).unpack1("l<")
        offset += 4
        format = payload.getbyte(offset)
        offset += 1
        nullable = payload.getbyte(offset) == 1
        offset += 1
        offset += 2
        columns << { name: name, table_oid: table_oid, column_index: column_index, type_oid: type_oid,
                    type_size: type_size, type_modifier: type_modifier, format: format, nullable: nullable }
      end
      columns
    end

    def self.parse_data_row(payload)
      raise "Row data truncated" if payload.bytesize < 4
      offset = 0
      count = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      null_bytes = payload.byteslice(offset, 2).unpack1("v")
      offset += 2
      null_bitmap = payload.byteslice(offset, null_bytes)
      offset += null_bytes
      values = []
      count.times do |idx|
        byte_index = idx / 8
        bit_index = idx % 8
        is_null = byte_index < null_bytes && ((null_bitmap.getbyte(byte_index) & (1 << bit_index)) != 0)
        if is_null
          values << { data: nil }
          next
        end
        length = payload.byteslice(offset, 4).unpack1("l<")
        offset += 4
        if length < 0
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
      raise "Command complete truncated" if payload.bytesize < 20
      command_type = payload.getbyte(0)
      rows = payload.byteslice(4, 8).unpack1("Q<")
      last_id = payload.byteslice(12, 8).unpack1("Q<")
      tag_bytes = payload.byteslice(20, payload.bytesize - 20)
      tag = tag_bytes ? tag_bytes.split("\0", 2).first.to_s : ""
      [command_type, rows, last_id, tag]
    end

    def self.parse_error_message(payload)
      offset = 0
      severity = ""
      sqlstate = ""
      message = ""
      detail = ""
      hint = ""
      while offset < payload.bytesize
        field = payload.getbyte(offset)
        offset += 1
        break if field == 0
        start = offset
        offset += 1 while offset < payload.bytesize && payload.getbyte(offset) != 0
        break if offset >= payload.bytesize
        value = payload.byteslice(start, offset - start).to_s
        offset += 1
        case field.chr
        when "S" then severity = value
        when "C" then sqlstate = value
        when "M" then message = value
        when "D" then detail = value
        when "H" then hint = value
        end
      end
      [severity, sqlstate, message, detail, hint]
    end

    def self.pad_bytes(data, length)
      return data if data.bytesize == length
      return data.byteslice(0, length) if data.bytesize > length
      data + "\0" * (length - data.bytesize)
    end
  end
end
