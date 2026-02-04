# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
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
