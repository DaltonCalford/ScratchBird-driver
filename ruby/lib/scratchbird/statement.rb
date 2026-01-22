require "scratchbird/errors"
require "scratchbird/sql"

module Scratchbird
  class Statement
    def initialize(connection, sql)
      @connection = connection
      @sql = sql
      @closed = false
    end

    def execute(params = nil)
      ensure_open
      @connection.execute(@sql, params)
    end

    def stream(params = nil)
      ensure_open
      @connection.stream(@sql, params)
    end

    def close
      @closed = true
    end

    def closed?
      @closed
    end

    private

    def ensure_open
      raise Error, "statement is closed" if @closed
    end
  end
end
