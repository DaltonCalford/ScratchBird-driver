require "bigdecimal"
require "time"

module Scratchbird
  module Types
    WIRE_BOOL = 0x01
    WIRE_INT16 = 0x02
    WIRE_INT32 = 0x03
    WIRE_INT64 = 0x04
    WIRE_FLOAT32 = 0x05
    WIRE_FLOAT64 = 0x06
    WIRE_DECIMAL = 0x07
    WIRE_VARCHAR = 0x08
    WIRE_CHAR = 0x09
    WIRE_BYTEA = 0x0A
    WIRE_DATE = 0x0B
    WIRE_TIME = 0x0C
    WIRE_TIMESTAMP = 0x0D
    WIRE_TIMESTAMPTZ = 0x0E
    WIRE_INTERVAL = 0x0F
    WIRE_UUID = 0x10
    WIRE_JSON = 0x11
    WIRE_JSONB = 0x12
    WIRE_ARRAY = 0x13
    WIRE_VECTOR = 0x16
    WIRE_MONEY = 0x17
    WIRE_XML = 0x18
    WIRE_INET = 0x19
    WIRE_CIDR = 0x1A
    WIRE_TSVECTOR = 0x1C
    WIRE_TSQUERY = 0x1D

    def self.decode(wire_type, data)
      return nil if data.nil?
      case wire_type
      when WIRE_BOOL
        data.getbyte(0) == 1
      when WIRE_INT16
        data.unpack1("s<")
      when WIRE_INT32
        data.unpack1("l<")
      when WIRE_INT64
        data.unpack1("q<")
      when WIRE_FLOAT32
        data.unpack1("e")
      when WIRE_FLOAT64
        data.unpack1("E")
      when WIRE_DECIMAL
        BigDecimal(data)
      when WIRE_VARCHAR, WIRE_CHAR, WIRE_JSON, WIRE_JSONB, WIRE_XML, WIRE_TSVECTOR, WIRE_TSQUERY
        data.force_encoding("UTF-8")
      when WIRE_BYTEA
        data
      when WIRE_DATE
        days = data.unpack1("l<")
        Time.utc(2000, 1, 1) + (days * 86_400)
      when WIRE_TIME
        micros = data.unpack1("q<")
        Time.at(0, micros, :usec).utc
      when WIRE_TIMESTAMP, WIRE_TIMESTAMPTZ
        micros = data.unpack1("q<")
        Time.at(micros / 1_000_000.0).utc
      when WIRE_INTERVAL
        months = data.byteslice(0, 4).unpack1("l<")
        days = data.byteslice(4, 4).unpack1("l<")
        micros = data.byteslice(8, 8).unpack1("q<")
        { months: months, days: days, micros: micros }
      when WIRE_UUID
        bytes_to_uuid(data)
      when WIRE_MONEY
        cents = data.unpack1("q<")
        BigDecimal(cents) / 100
      when WIRE_INET, WIRE_CIDR
        data.force_encoding("UTF-8")
      when WIRE_ARRAY
        parse_array_literal(data.force_encoding("UTF-8"))
      when WIRE_VECTOR
        parse_vector_literal(data.force_encoding("UTF-8"))
      else
        data
      end
    end

    def self.bytes_to_uuid(data)
      hex = data.unpack1("H*")
      return hex unless hex.length == 32
      "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
    end

    def self.parse_array_literal(text)
      trimmed = text.to_s.strip
      return [] if trimmed.empty? || trimmed == "{}"
      trimmed = trimmed[1..-2] if trimmed.start_with?("{") && trimmed.end_with?("}")
      split_array_items(trimmed)
    end

    def self.split_array_items(text)
      items = []
      depth = 0
      buffer = +""
      text.each_char do |ch|
        if ch == "{"
          depth += 1
          buffer << ch
        elsif ch == "}"
          depth -= 1 if depth > 0
          buffer << ch
        elsif ch == "," && depth.zero?
          items << parse_array_item(buffer)
          buffer.clear
        else
          buffer << ch
        end
      end
      items << parse_array_item(buffer) if !buffer.empty? || !text.empty?
      items
    end

    def self.parse_array_item(raw)
      token = raw.to_s.strip
      return nil if token.casecmp("NULL").zero?
      if token.start_with?("{") && token.end_with?("}")
        return parse_array_literal(token)
      end
      if token.start_with?("[") && token.end_with?("]")
        return parse_vector_literal(token)
      end
      return true if token.casecmp("true").zero?
      return false if token.casecmp("false").zero?
      return token.to_i if token.match?(/\A-?\d+\z/)
      return token.to_f if token.match?(/\A-?\d+\.\d+\z/)
      token
    end

    def self.parse_vector_literal(text)
      trimmed = text.to_s.strip
      trimmed = trimmed[1..-2] if trimmed.start_with?("[") && trimmed.end_with?("]")
      return [] if trimmed.empty?
      trimmed.split(",").map { |item| item.strip.to_f }
    end
  end
end
