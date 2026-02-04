# ScratchBird metadata helper queries (sys.*)

sb_metadata_schemas_query <- function() {
  "SELECT schema_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
}

sb_metadata_tables_query <- function() {
  "SELECT t.table_name, s.schema_name, t.table_type FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE t.is_valid = 1 ORDER BY t.table_name"
}

sb_metadata_columns_query <- function() {
  paste(
    "SELECT c.column_name, t.table_name, s.schema_name, c.data_type_id, c.ordinal_position, c.is_nullable, c.default_value",
    "FROM sys.columns c",
    "JOIN sys.tables t ON t.table_id = c.table_id",
    "JOIN sys.schemas s ON s.schema_id = t.schema_id",
    "WHERE c.is_valid = 1",
    "ORDER BY s.schema_name, t.table_name, c.ordinal_position"
  )
}
