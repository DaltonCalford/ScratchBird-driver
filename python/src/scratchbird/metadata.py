"""Metadata helper queries for ScratchBird sys.* views."""

SCHEMAS_QUERY = "SELECT schema_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
TABLES_QUERY = (
    "SELECT t.table_name, s.schema_name, t.table_type "
    "FROM sys.tables t "
    "JOIN sys.schemas s ON s.schema_id = t.schema_id "
    "WHERE t.is_valid = 1 ORDER BY t.table_name"
)
COLUMNS_QUERY = (
    "SELECT c.column_name, t.table_name, s.schema_name, c.data_type_id, "
    "c.ordinal_position, c.is_nullable, c.default_value "
    "FROM sys.columns c "
    "JOIN sys.tables t ON t.table_id = c.table_id "
    "JOIN sys.schemas s ON s.schema_id = t.schema_id "
    "WHERE c.is_valid = 1 "
    "ORDER BY s.schema_name, t.table_name, c.ordinal_position"
)


def schemas_query() -> str:
    return SCHEMAS_QUERY


def tables_query() -> str:
    return TABLES_QUERY


def columns_query() -> str:
    return COLUMNS_QUERY
