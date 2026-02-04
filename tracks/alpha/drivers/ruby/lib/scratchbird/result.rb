# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
module Scratchbird
  Column = Struct.new(:name, :type_oid, :type_modifier, :format, :nullable, keyword_init: true)

  class Result
    attr_reader :columns, :rowcount, :command_tag

    def initialize(columns, rows, rowcount, command_tag = "")
      @columns = (columns || []).map do |col|
        Column.new(
          name: col[:name],
          type_oid: col[:type_oid],
          type_modifier: col[:type_modifier],
          format: col[:format],
          nullable: col[:nullable]
        )
      end
      @rows = rows || []
      @rowcount = rowcount.to_i
      @command_tag = command_tag.to_s
    end

    def rows
      @rows
    end

    def fields
      @columns.map(&:name)
    end

    def each
      return enum_for(:each) unless block_given?
      @rows.each { |row| yield row }
    end

    def each_hash
      return enum_for(:each_hash) unless block_given?
      @rows.each do |row|
        yield to_hash(row)
      end
    end

    def first
      @rows.first
    end

    private

    def to_hash(row)
      data = {}
      @columns.each_with_index do |col, idx|
        key = col.name || idx
        data[key] = row[idx]
      end
      data
    end
  end
end
