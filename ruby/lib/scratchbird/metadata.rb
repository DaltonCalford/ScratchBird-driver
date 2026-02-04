# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

module Scratchbird
  module Metadata
    SCHEMAS_QUERY = "SELECT schema_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
    TABLES_QUERY = "SELECT t.table_name, s.schema_name, t.table_type FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE t.is_valid = 1 ORDER BY t.table_name"
    COLUMNS_QUERY = "SELECT c.column_name, t.table_name, s.schema_name, c.data_type_id, c.ordinal_position, c.is_nullable, c.default_value FROM sys.columns c JOIN sys.tables t ON t.table_id = c.table_id JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE c.is_valid = 1 ORDER BY s.schema_name, t.table_name, c.ordinal_position"

    def self.schemas_query
      SCHEMAS_QUERY
    end

    def self.tables_query
      TABLES_QUERY
    end

    def self.columns_query
      COLUMNS_QUERY
    end
  end
end
