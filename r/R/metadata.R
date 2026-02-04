# ScratchBird metadata helper queries (sys.*)

sb_metadata_schemas_query <- function() {
  "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
}

sb_metadata_tables_query <- function() {
  "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
}

sb_metadata_columns_query <- function() {
  paste(
    "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression",
    "FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
  )
}

sb_metadata_indexes_query <- function() {
  "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
}

sb_metadata_index_columns_query <- function() {
  "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
}

sb_metadata_constraints_query <- function() {
  "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
}

sb_metadata_procedures_query <- function() {
  "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
}

sb_metadata_functions_query <- function() {
  "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
}
