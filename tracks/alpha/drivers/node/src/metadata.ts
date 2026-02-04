// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

export const METADATA_SCHEMAS_QUERY =
  "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name";

export const METADATA_TABLES_QUERY =
  "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name";

export const METADATA_COLUMNS_QUERY =
  "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position";

export const METADATA_INDEXES_QUERY =
  "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name";

export const METADATA_INDEX_COLUMNS_QUERY =
  "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position";

export const METADATA_CONSTRAINTS_QUERY =
  "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name";

export const METADATA_PROCEDURES_QUERY =
  "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name";

export const METADATA_FUNCTIONS_QUERY =
  "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name";
