module Scratchbird
  class Error < StandardError
    attr_reader :sqlstate, :detail, :hint

    def initialize(message, sqlstate = "", detail = "", hint = "")
      super(message)
      @sqlstate = sqlstate
      @detail = detail
      @hint = hint
    end
  end

  class Warning < Error; end
  class NoDataError < Error; end
  class ConnectionError < Error; end
  class NotSupportedError < Error; end
  class DataError < Error; end
  class IntegrityError < Error; end
  class AuthError < Error; end
  class TransactionError < Error; end
  class SyntaxError < Error; end
  class ResourceError < Error; end
  class LimitError < Error; end
  class OperatorInterventionError < Error; end
  class SystemError < Error; end
  class InternalError < Error; end

  module ErrorMapper
    def self.from_sqlstate(sqlstate, message, detail = "", hint = "")
      prefix = sqlstate.to_s[0, 2] || ""
      case prefix
      when "01" then Warning.new(message, sqlstate, detail, hint)
      when "02" then NoDataError.new(message, sqlstate, detail, hint)
      when "08" then ConnectionError.new(message, sqlstate, detail, hint)
      when "0A" then NotSupportedError.new(message, sqlstate, detail, hint)
      when "22" then DataError.new(message, sqlstate, detail, hint)
      when "23" then IntegrityError.new(message, sqlstate, detail, hint)
      when "28" then AuthError.new(message, sqlstate, detail, hint)
      when "40" then TransactionError.new(message, sqlstate, detail, hint)
      when "42" then SyntaxError.new(message, sqlstate, detail, hint)
      when "53" then ResourceError.new(message, sqlstate, detail, hint)
      when "54" then LimitError.new(message, sqlstate, detail, hint)
      when "57" then OperatorInterventionError.new(message, sqlstate, detail, hint)
      when "58" then SystemError.new(message, sqlstate, detail, hint)
      when "XX" then InternalError.new(message, sqlstate, detail, hint)
      else
        Error.new(message, sqlstate, detail, hint)
      end
    end
  end
end
