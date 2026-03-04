# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""ScratchBird DB-API 2.0 driver."""

from .connection import Connection, connect
from .errors import (
    Warning,
    Error,
    InterfaceError,
    DatabaseError,
    DataError,
    OperationalError,
    IntegrityError,
    InternalError,
    ProgrammingError,
    NotSupportedError,
)
from .types import Geometry, Json, Jsonb, Range, RawValue
from .protocol import COPY_FORMAT_TEXT, COPY_FORMAT_BINARY
from .pool import (
    ConnectionPool,
    PoolConfig,
    StatementCache,
    CachingConnection,
    retry_with_backoff,
)
from .metadata import (
    SchemaTreeNode,
    schemas_query,
    tables_query,
    columns_query,
    indexes_query,
    index_columns_query,
    constraints_query,
    procedures_query,
    functions_query,
    routines_query,
    catalogs_query,
    primary_keys_query,
    foreign_keys_query,
    table_privileges_query,
    column_privileges_query,
    type_info_query,
    normalize_collection_name,
    normalize_restrictions,
    resolve_collection_query,
    filter_rows_by_restrictions,
    schema_name_matches_pattern,
    schema_paths_for_navigation,
    expand_schema_parent_paths,
    build_schema_tree,
)

apilevel = "2.0"
threadsafety = 2
paramstyle = "named"

__all__ = [
    "connect",
    "Connection",
    "ConnectionPool",
    "PoolConfig",
    "StatementCache",
    "CachingConnection",
    "retry_with_backoff",
    "Warning",
    "Error",
    "InterfaceError",
    "DatabaseError",
    "DataError",
    "OperationalError",
    "IntegrityError",
    "InternalError",
    "ProgrammingError",
    "NotSupportedError",
    "Json",
    "Jsonb",
    "Geometry",
    "Range",
    "RawValue",
    "COPY_FORMAT_TEXT",
    "COPY_FORMAT_BINARY",
    "SchemaTreeNode",
    "schemas_query",
    "tables_query",
    "columns_query",
    "indexes_query",
    "index_columns_query",
    "constraints_query",
    "procedures_query",
    "functions_query",
    "routines_query",
    "catalogs_query",
    "primary_keys_query",
    "foreign_keys_query",
    "table_privileges_query",
    "column_privileges_query",
    "type_info_query",
    "normalize_collection_name",
    "normalize_restrictions",
    "resolve_collection_query",
    "filter_rows_by_restrictions",
    "schema_name_matches_pattern",
    "schema_paths_for_navigation",
    "expand_schema_parent_paths",
    "build_schema_tree",
]
