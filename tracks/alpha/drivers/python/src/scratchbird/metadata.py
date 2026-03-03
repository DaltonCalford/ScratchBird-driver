"""Metadata query helpers and schema-tree shaping utilities."""

from __future__ import annotations

from dataclasses import dataclass, field
import re
from typing import Dict, Iterable, List, Optional, Set

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
ROUTINES_QUERY = (
    "SELECT procedure_id AS routine_id, schema_id, procedure_name AS routine_name, routine_type "
    "FROM sys.procedures WHERE is_valid = 1 "
    "UNION ALL "
    "SELECT function_id AS routine_id, schema_id, function_name AS routine_name, 'FUNCTION' AS routine_type "
    "FROM sys.functions WHERE is_valid = 1 "
    "ORDER BY schema_id, routine_name"
)
CATALOGS_QUERY = (
    "SELECT schema_id AS catalog_id, schema_name AS catalog_name "
    "FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
)
PRIMARY_KEYS_QUERY = (
    "SELECT constraint_id, table_id, constraint_name, constraint_type "
    "FROM sys.constraints WHERE is_valid = 1 "
    "AND lower(constraint_type) IN ('primary key', 'primary') "
    "ORDER BY table_id, constraint_name"
)
FOREIGN_KEYS_QUERY = (
    "SELECT constraint_id, table_id, constraint_name, constraint_type "
    "FROM sys.constraints WHERE is_valid = 1 "
    "AND lower(constraint_type) IN ('foreign key', 'foreign') "
    "ORDER BY table_id, constraint_name"
)
TABLE_PRIVILEGES_QUERY = (
    "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, "
    "'ALL' AS privilege_type "
    "FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name"
)
COLUMN_PRIVILEGES_QUERY = (
    "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type "
    "FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
)
TYPE_INFO_QUERY = (
    "SELECT DISTINCT data_type_id, data_type_name "
    "FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name"
)

DEFAULT_COLLECTION = "tables"

COLLECTION_QUERY_MAP: Dict[str, str] = {
    "schemas": SCHEMAS_QUERY,
    "tables": TABLES_QUERY,
    "columns": COLUMNS_QUERY,
    "indexes": INDEXES_QUERY,
    "index_columns": INDEX_COLUMNS_QUERY,
    "constraints": CONSTRAINTS_QUERY,
    "procedures": PROCEDURES_QUERY,
    "functions": FUNCTIONS_QUERY,
    "routines": ROUTINES_QUERY,
    "catalogs": CATALOGS_QUERY,
    "primary_keys": PRIMARY_KEYS_QUERY,
    "foreign_keys": FOREIGN_KEYS_QUERY,
    "table_privileges": TABLE_PRIVILEGES_QUERY,
    "column_privileges": COLUMN_PRIVILEGES_QUERY,
    "type_info": TYPE_INFO_QUERY,
}

COLLECTION_ALIASES: Dict[str, str] = {
    "schema": "schemas",
    "schemas": "schemas",
    "table": "tables",
    "tables": "tables",
    "column": "columns",
    "columns": "columns",
    "index": "indexes",
    "indexes": "indexes",
    "index_column": "index_columns",
    "index_columns": "index_columns",
    "indexcolumn": "index_columns",
    "indexcolumns": "index_columns",
    "constraint": "constraints",
    "constraints": "constraints",
    "procedure": "procedures",
    "procedures": "procedures",
    "function": "functions",
    "functions": "functions",
    "routine": "routines",
    "routines": "routines",
    "catalog": "catalogs",
    "catalogs": "catalogs",
    "primary_key": "primary_keys",
    "primary_keys": "primary_keys",
    "primarykey": "primary_keys",
    "primarykeys": "primary_keys",
    "foreign_key": "foreign_keys",
    "foreign_keys": "foreign_keys",
    "foreignkey": "foreign_keys",
    "foreignkeys": "foreign_keys",
    "table_privilege": "table_privileges",
    "table_privileges": "table_privileges",
    "tableprivilege": "table_privileges",
    "tableprivileges": "table_privileges",
    "column_privilege": "column_privileges",
    "column_privileges": "column_privileges",
    "columnprivilege": "column_privileges",
    "columnprivileges": "column_privileges",
    "type_info": "type_info",
    "typeinfo": "type_info",
}


@dataclass
class SchemaTreeNode:
    """Metadata-only schema tree node for recursive navigation surfaces."""

    name: str
    full_path: str
    is_terminal: bool = False
    children: List["SchemaTreeNode"] = field(default_factory=list)


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


def routines_query() -> str:
    return ROUTINES_QUERY


def catalogs_query() -> str:
    return CATALOGS_QUERY


def primary_keys_query() -> str:
    return PRIMARY_KEYS_QUERY


def foreign_keys_query() -> str:
    return FOREIGN_KEYS_QUERY


def table_privileges_query() -> str:
    return TABLE_PRIVILEGES_QUERY


def column_privileges_query() -> str:
    return COLUMN_PRIVILEGES_QUERY


def type_info_query() -> str:
    return TYPE_INFO_QUERY


def normalize_collection_name(collection_name: Optional[str] = None) -> str:
    raw = DEFAULT_COLLECTION if collection_name is None else str(collection_name)
    normalized = raw.strip().lower().replace("-", "_").replace(" ", "_")
    if not normalized:
        normalized = DEFAULT_COLLECTION
    collapsed = normalized.replace("_", "")
    resolved = COLLECTION_ALIASES.get(normalized) or COLLECTION_ALIASES.get(collapsed)
    if resolved is None:
        raise ValueError(f"metadata collection '{raw}' is not supported")
    return resolved


def resolve_collection_query(collection_name: Optional[str] = None) -> str:
    resolved = normalize_collection_name(collection_name)
    return COLLECTION_QUERY_MAP[resolved]


def schema_name_matches_pattern(schema_name: Optional[str], schema_pattern: Optional[str]) -> bool:
    """Return True when a schema name matches JDBC-style `%`/`_` wildcard pattern."""
    if not schema_pattern:
        return True
    if schema_name is None:
        return False
    return bool(_pattern_to_regex(schema_pattern).match(schema_name))


def schema_paths_for_navigation(
    schema_names: Iterable[str],
    *,
    expand_schema_parents: bool = False,
    schema_pattern: Optional[str] = None,
) -> List[str]:
    """
    Normalize, de-duplicate, and filter schema paths for metadata navigation.

    When `expand_schema_parents` is True, dotted parent segments are emitted in
    insertion order (for example `users`, `users.alice`, `users.alice.dev`).
    """
    if expand_schema_parents:
        return expand_schema_parent_paths(schema_names, schema_pattern=schema_pattern)

    out: List[str] = []
    seen: Set[str] = set()
    for schema_name in schema_names:
        normalized = _normalize_schema_name(schema_name)
        if normalized is None:
            continue
        if not schema_name_matches_pattern(normalized, schema_pattern):
            continue
        if normalized in seen:
            continue
        seen.add(normalized)
        out.append(normalized)
    return out


def expand_schema_parent_paths(
    schema_names: Iterable[str],
    *,
    schema_pattern: Optional[str] = None,
) -> List[str]:
    """
    Expand dotted schema names to include parent segments.

    Behavior mirrors the JDBC metadata expansion mode:
    `users.alice.dev` -> `users`, `users.alice`, `users.alice.dev`.
    """
    out: List[str] = []
    seen: Set[str] = set()
    for schema_name in schema_names:
        parts = _split_schema_path(schema_name)
        if not parts:
            continue
        current: List[str] = []
        for part in parts:
            current.append(part)
            candidate = ".".join(current)
            if not schema_name_matches_pattern(candidate, schema_pattern):
                continue
            if candidate in seen:
                continue
            seen.add(candidate)
            out.append(candidate)
    return out


def build_schema_tree(schema_paths: Iterable[str]) -> List[SchemaTreeNode]:
    """
    Build a metadata-only recursive schema tree from dotted schema paths.

    - Child name uniqueness is enforced per parent.
    - Same-name nodes in different schema paths are preserved as distinct nodes.
    """
    nodes_by_path: Dict[str, SchemaTreeNode] = {}
    roots: List[SchemaTreeNode] = []

    for schema_path in schema_paths:
        parts = _split_schema_path(schema_path)
        if not parts:
            continue

        parent: Optional[SchemaTreeNode] = None
        current_path: List[str] = []
        for part in parts:
            current_path.append(part)
            full_path = ".".join(current_path)
            node = nodes_by_path.get(full_path)
            if node is None:
                node = SchemaTreeNode(name=part, full_path=full_path)
                nodes_by_path[full_path] = node
                if parent is None:
                    roots.append(node)
                else:
                    parent.children.append(node)
            parent = node

        if parent is not None:
            parent.is_terminal = True

    return roots


def _normalize_schema_name(schema_name: Optional[str]) -> Optional[str]:
    parts = _split_schema_path(schema_name)
    if not parts:
        return None
    return ".".join(parts)


def _split_schema_path(schema_name: Optional[str]) -> List[str]:
    if schema_name is None:
        return []
    parts: List[str] = []
    for part in str(schema_name).split("."):
        normalized = part.strip()
        if normalized:
            parts.append(normalized)
    return parts


def _pattern_to_regex(pattern: str) -> re.Pattern[str]:
    out = ["^"]
    escaped = False
    for ch in pattern:
        if escaped:
            out.append(re.escape(ch))
            escaped = False
            continue
        if ch == "\\":
            escaped = True
            continue
        if ch == "%":
            out.append(".*")
        elif ch == "_":
            out.append(".")
        else:
            out.append(re.escape(ch))
    out.append("$")
    return re.compile("".join(out), re.IGNORECASE)
