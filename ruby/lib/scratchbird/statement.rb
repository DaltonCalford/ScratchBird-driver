require "scratchbird/errors"
require "scratchbird/sql"

module Scratchbird
  class Statement
    def initialize(connection, sql)
      @connection = connection
      @sql = sql
      @name = "sb_stmt_#{object_id}"
      @closed = false
      @connection.client.prepare(@name, @sql)
    end

    def execute(params = nil)
      ensure_open
      @connection.client.execute(@name, params)
    end

    def stream(params = nil)
      ensure_open
      @connection.client.execute_stream(@name, params)
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
