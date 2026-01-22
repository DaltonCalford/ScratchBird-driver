require "date"
require "json"
require "ipaddr"
require "bigdecimal"

module Scratchbird
  module Sql
    def self.substitute(sql, params)
      return sql if params.nil? || params.empty?
      if has_named_params?(sql)
        substitute_named(sql, params)
      else
        substitute_positional(sql, params)
      end
    end

    def self.has_named_params?(sql)
      sql.each_char.with_index do |ch, idx|
        next unless (ch == ":" || ch == "@") && idx + 1 < sql.length
        return true if sql[idx + 1] =~ /[A-Za-z]/
      end
      false
    end

    def self.substitute_named(sql, params)
      lookup = {}
      params.each do |key, value|
        next unless key.is_a?(String) || key.is_a?(Symbol)
        lookup[key.to_s.sub(/\A[@:]/, "")] = value
      end
      out = +""
      i = 0
      while i < sql.length
        ch = sql[i]
        if ch == "'" && i + 1 < sql.length
          out << ch
          i += 1
          while i < sql.length
            out << sql[i]
            if sql[i] == "'" && (i + 1 >= sql.length || sql[i + 1] != "'")
              i += 1
              break
            end
            if sql[i] == "'" && i + 1 < sql.length && sql[i + 1] == "'"
              i += 1
            end
            i += 1
          end
          next
        end
        if (ch == ":" || ch == "@") && i + 1 < sql.length && sql[i + 1] =~ /[A-Za-z]/
          j = i + 1
          j += 1 while j < sql.length && sql[j] =~ /[A-Za-z0-9_]/
          name = sql[(i + 1)...j]
          if lookup.key?(name)
            out << format_value(lookup[name])
          else
            out << sql[i...j]
          end
          i = j
          next
        end
        out << ch
        i += 1
      end
      out
    end

    def self.substitute_positional(sql, params)
      out = +""
      idx = 0
      i = 0
      while i < sql.length
        ch = sql[i]
        if ch == "?"
          if idx < params.length
            out << format_value(params[idx])
            idx += 1
          else
            out << ch
          end
          i += 1
          next
        end
        if ch == "$" && i + 1 < sql.length && sql[i + 1] =~ /\d/
          j = i + 1
          num = 0
          while j < sql.length && sql[j] =~ /\d/
            num = num * 10 + sql[j].ord - "0".ord
            j += 1
          end
          if num > 0 && num <= params.length
            out << format_value(params[num - 1])
          else
            out << sql[i...j]
          end
          i = j
          next
        end
        if ch == "'" && i + 1 < sql.length
          out << ch
          i += 1
          while i < sql.length
            out << sql[i]
            if sql[i] == "'" && (i + 1 >= sql.length || sql[i + 1] != "'")
              i += 1
              break
            end
            if sql[i] == "'" && i + 1 < sql.length && sql[i + 1] == "'"
              i += 1
            end
            i += 1
          end
          next
        end
        out << ch
        i += 1
      end
      out
    end

    def self.format_value(value)
      return "NULL" if value.nil?
      case value
      when TrueClass then "TRUE"
      when FalseClass then "FALSE"
      when Integer, Float then value.to_s
      when BigDecimal then value.to_s("F")
      when Time
        "TIMESTAMP '#{value.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')}'"
      when DateTime
        "TIMESTAMP '#{value.to_time.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')}'"
      when Date
        "DATE '#{value.strftime('%Y-%m-%d')}'"
      when IPAddr
        "INET '#{escape(value.to_s)}'"
      when String
        if value.encoding == Encoding::BINARY
          "X'#{value.unpack1('H*').upcase}'"
        else
          "'#{escape(value)}'"
        end
      when Symbol
        "'#{escape(value.to_s)}'"
      when Array
        "ARRAY[#{value.map { |item| format_value(item) }.join(', ')}]"
      when Hash
        payload = JSON.generate(value)
        "JSON '#{escape(payload)}'"
      else
        "'#{escape(value.to_s)}'"
      end
    end

    def self.escape(value)
      value.gsub("\\", "\\\\").gsub("'", "''")
    end
  end
end
