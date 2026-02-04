"""Metadata helper queries for ScratchBird sys.* views."""

SCHEMAS_QUERY = (
    "SELECT schema_id, schema_name, owner_id, default_tablespace_id "
    "FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
)
TABLES_QUERY = (
    "SELECT table_id, schema_id, table_name, table_type, owner_id "
    "FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
)
COLUMNS_QUERY = (
    "SELECT column_id, table_id, column_name, data_type_id, data_type_name, "
    "ordinal_position, is_nullable, default_value, domain_id, collation_id, "
    "charset_id, is_identity, is_generated, generation_expression "
    "FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
)
INDEXES_QUERY = (
    "SELECT index_id, table_id, index_name, index_type, is_unique "
    "FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
)
INDEX_COLUMNS_QUERY = (
    "SELECT index_id, column_id, column_name, ordinal_position, is_included "
    "FROM sys.index_columns ORDER BY index_id, ordinal_position"
)
CONSTRAINTS_QUERY = (
    "SELECT constraint_id, table_id, constraint_name, constraint_type "
    "FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
)
PROCEDURES_QUERY = (
    "SELECT procedure_id, schema_id, procedure_name, routine_type "
    "FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
)
FUNCTIONS_QUERY = (
    "SELECT function_id, schema_id, function_name "
    "FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
)


def schemas_query() -> str:
    return SCHEMAS_QUERY


def tables_query() -> str:
    return TABLES_QUERY


def columns_query() -> str:
    return COLUMNS_QUERY


def indexes_query() -> str:
    return INDEXES_QUERY


def index_columns_query() -> str:
    return INDEX_COLUMNS_QUERY


def constraints_query() -> str:
    return CONSTRAINTS_QUERY


def procedures_query() -> str:
    return PROCEDURES_QUERY


def functions_query() -> str:
    return FUNCTIONS_QUERY
