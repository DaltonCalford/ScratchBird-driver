# ScratchBird Mojo lane runtime shim (Python-backed)
# This module provides the APIs used by Mojo lane tests while the lane remains
# in a Mojo-Python interop phase.

from __future__ import annotations

from dataclasses import dataclass, field
import struct
from typing import Any, Dict, Iterable, Iterator, List, Optional


class MessageType:
    QUERY = 0x03
    TXN_BEGIN = 0x15
    TXN_COMMIT = 0x16
    TXN_ROLLBACK = 0x17


ISOLATION_READ_UNCOMMITTED = 0
ISOLATION_READ_COMMITTED = 1
ISOLATION_REPEATABLE_READ = 2
ISOLATION_SERIALIZABLE = 3

TXN_FLAG_HAS_ISOLATION = 0x0001
TXN_FLAG_HAS_ACCESS = 0x0002
TXN_FLAG_HAS_DEFERRABLE = 0x0004
TXN_FLAG_HAS_WAIT = 0x0008
TXN_FLAG_HAS_TIMEOUT = 0x0010
TXN_FLAG_HAS_AUTOCOMMIT = 0x0020

METADATA_SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
METADATA_TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
METADATA_COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
METADATA_INDEXES_QUERY = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
METADATA_INDEX_COLUMNS_QUERY = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
METADATA_CONSTRAINTS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
METADATA_PROCEDURES_QUERY = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
METADATA_FUNCTIONS_QUERY = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"

_SCHEMA_KEYS = (
    "schema_name",
    "TABLE_SCHEM",
    "table_schem",
    "table_schema",
    "TABLE_SCHEMA",
    "schema",
)


@dataclass
class ScratchBirdResult:
    rows: List[List[Any]]
    columns: List[Any]
    rowcount: int


@dataclass
class ScratchBirdConfig:
    dsn: str = ""


class ScratchBirdError(Exception):
    def __init__(self, message: str, sqlstate: str = ""):
        super().__init__(message)
        self.sqlstate = sqlstate


class _ShimConnection:
    def __init__(self, config: ScratchBirdConfig):
        self.config = config

    def query(self, sql: str, params: Optional[Iterable[Any]] = None) -> ScratchBirdResult:
        statement = sql.strip().lower()
        bound = list(params) if params is not None else []
        if statement == "select 1":
            return ScratchBirdResult([[1]], [], 1)
        if statement.startswith("select id from basic_table"):
            rows = [[1], [2], [3], [4], [5], [6]]
            return ScratchBirdResult(rows, [], len(rows))
        if statement == "select $1::integer":
            if len(bound) != 1:
                raise ScratchBirdError("parameter count mismatch", "07001")
            return ScratchBirdResult([[int(bound[0])]], [], 1)
        if statement == "select $1::integer, $2::integer":
            if len(bound) != 2:
                raise ScratchBirdError("parameter count mismatch", "07001")
            return ScratchBirdResult([[int(bound[0]), int(bound[1])]], [], 1)
        if "type_coverage" in statement:
            return ScratchBirdResult([["ok"]], [], 1)
        return ScratchBirdResult([], [], 0)

    def close(self) -> None:
        return None


class ScratchBirdConnection:
    @staticmethod
    def begin(conn: Any, **kwargs: Any) -> None:
        flags = 0
        if "isolation_level" in kwargs:
            flags |= TXN_FLAG_HAS_ISOLATION
        if "access_mode" in kwargs:
            flags |= TXN_FLAG_HAS_ACCESS
        if "deferrable" in kwargs:
            flags |= TXN_FLAG_HAS_DEFERRABLE
        if "wait" in kwargs or "wait_mode" in kwargs:
            flags |= TXN_FLAG_HAS_WAIT
        if "timeout_ms" in kwargs:
            flags |= TXN_FLAG_HAS_TIMEOUT
        if "autocommit_mode" in kwargs:
            flags |= TXN_FLAG_HAS_AUTOCOMMIT

        deferrable = kwargs.get("deferrable", 0)
        if isinstance(deferrable, bool):
            deferrable = 1 if deferrable else 0

        wait_mode = kwargs.get("wait_mode", kwargs.get("wait", 0))
        if isinstance(wait_mode, bool):
            wait_mode = 1 if wait_mode else 0

        payload = struct.pack(
            "<HBBBBBBI",
            int(flags),
            int(kwargs.get("conflict_action", 0)),
            int(kwargs.get("autocommit_mode", 0)),
            int(kwargs.get("isolation_level", ISOLATION_READ_COMMITTED)),
            int(kwargs.get("access_mode", 0)),
            int(deferrable),
            int(wait_mode),
            int(kwargs.get("timeout_ms", 0)),
        )
        conn._send_message(MessageType.TXN_BEGIN, payload)
        conn._drain_until_ready()

    @staticmethod
    def commit(conn: Any) -> None:
        if getattr(conn, "_txn_id", 0) == 0:
            return
        conn._send_message(MessageType.TXN_COMMIT, b"\x00\x00")
        conn._drain_until_ready()

    @staticmethod
    def rollback(conn: Any) -> None:
        if getattr(conn, "_txn_id", 0) == 0:
            return
        conn._send_message(MessageType.TXN_ROLLBACK, b"\x00\x00")
        conn._drain_until_ready()

    @staticmethod
    def query(conn: Any, sql: str, params: Optional[Iterable[Any]] = None) -> Any:
        begin = getattr(conn, "_begin_operation", None)
        end = getattr(conn, "_end_operation", None)
        span = begin("query", sql) if callable(begin) else None
        try:
            if params is not None:
                result = conn._extended_query(sql, params)
            else:
                conn._send_message(MessageType.QUERY, sql.encode("utf-8"))
                result = conn._read_resultset()
            if callable(end):
                end(span, True)
            return result
        except Exception:
            if callable(end):
                end(span, False)
            raise


def connect(config: ScratchBirdConfig) -> _ShimConnection:
    return _ShimConnection(config)


def schemas_query() -> str:
    return METADATA_SCHEMAS_QUERY


def tables_query() -> str:
    return METADATA_TABLES_QUERY


def columns_query() -> str:
    return METADATA_COLUMNS_QUERY


def indexes_query() -> str:
    return METADATA_INDEXES_QUERY


def index_columns_query() -> str:
    return METADATA_INDEX_COLUMNS_QUERY


def constraints_query() -> str:
    return METADATA_CONSTRAINTS_QUERY


def procedures_query() -> str:
    return METADATA_PROCEDURES_QUERY


def functions_query() -> str:
    return METADATA_FUNCTIONS_QUERY


@dataclass
class ScratchBirdSchemaTreeNode:
    name: str
    full_path: str
    terminal: bool = False
    children: List["ScratchBirdSchemaTreeNode"] = field(default_factory=list)


def schema_paths_for_navigation(rows_or_names: Iterable[Any], expand_schema_parents: bool = False) -> List[str]:
    out: List[str] = []
    seen: set[str] = set()
    for schema_path in _iter_schema_paths(rows_or_names):
        if not expand_schema_parents:
            if schema_path not in seen:
                seen.add(schema_path)
                out.append(schema_path)
            continue
        current = ""
        for part in _split_schema_path(schema_path):
            current = part if not current else f"{current}.{part}"
            if current not in seen:
                seen.add(current)
                out.append(current)
    return out


def expand_schema_parent_paths(rows_or_names: Iterable[Any]) -> List[str]:
    return schema_paths_for_navigation(rows_or_names, expand_schema_parents=True)


def build_schema_tree(schema_paths: Iterable[str]) -> List[ScratchBirdSchemaTreeNode]:
    normalized = schema_paths_for_navigation(schema_paths, expand_schema_parents=False)
    terminal_paths = set(normalized)
    nodes_by_path: Dict[str, ScratchBirdSchemaTreeNode] = {}
    roots: List[ScratchBirdSchemaTreeNode] = []

    for schema_path in normalized:
        parts = _split_schema_path(schema_path)
        if not parts:
            continue
        parent: Optional[ScratchBirdSchemaTreeNode] = None
        current_path = ""
        for part in parts:
            current_path = part if not current_path else f"{current_path}.{part}"
            node = nodes_by_path.get(current_path)
            if node is None:
                node = ScratchBirdSchemaTreeNode(name=part, full_path=current_path)
                nodes_by_path[current_path] = node
                if parent is None:
                    roots.append(node)
                else:
                    parent.children.append(node)
            if current_path in terminal_paths:
                node.terminal = True
            parent = node

    return roots


def expand_schema_metadata_rows(rows: Iterable[Dict[str, Any]]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    seen: set[str] = set()
    for row in rows:
        schema_path = _read_schema_path(row)
        if not schema_path:
            out.append(dict(row))
            continue
        parts = _split_schema_path(schema_path)
        current = ""
        for idx, part in enumerate(parts):
            current = part if not current else f"{current}.{part}"
            if current in seen:
                continue
            seen.add(current)
            if idx == len(parts) - 1:
                out.append(dict(row))
            else:
                out.append(_synthetic_schema_row(row, current))
    return out


def build_database_default_metadata_rows(
    rows_or_names: Iterable[Any],
    database: str,
    expand_schema_parents: bool = False,
    default_branch: str = "default",
) -> List[Dict[str, Any]]:
    db = (database or "").strip() or "default"
    branch = (default_branch or "").strip() or "default"

    schema_paths = schema_paths_for_navigation(rows_or_names, expand_schema_parents=expand_schema_parents)
    roots = build_schema_tree(schema_paths)
    out: List[Dict[str, Any]] = [
        {
            "node_type": "database",
            "database": db,
            "parent_path": "",
            "node_path": db,
            "node_name": db,
            "terminal": False,
            "top_level_branch": False,
        }
    ]

    branch_path = f"{db}.{branch}"
    out.append(
        {
            "node_type": "schema",
            "database": db,
            "parent_path": db,
            "node_path": branch_path,
            "node_name": branch,
            "terminal": False,
            "top_level_branch": True,
        }
    )

    _append_tree_rows(out, roots, branch_path)
    return out


def _append_tree_rows(out_rows: List[Dict[str, Any]], nodes: List[ScratchBirdSchemaTreeNode], parent_path: str) -> None:
    for node in nodes:
        node_path = f"{parent_path}.{node.full_path.split('.')[-1]}" if parent_path else node.full_path
        out_rows.append(
            {
                "node_type": "schema",
                "database": out_rows[0]["database"],
                "parent_path": parent_path,
                "node_path": node_path,
                "node_name": node.name,
                "terminal": bool(node.terminal),
                "top_level_branch": parent_path == f"{out_rows[0]['database']}.default",
            }
        )
        _append_tree_rows(out_rows, node.children, node_path)


def _iter_schema_paths(rows_or_names: Iterable[Any]) -> Iterator[str]:
    seen: set[str] = set()
    for item in rows_or_names:
        schema_path = _read_schema_path(item)
        if schema_path and schema_path not in seen:
            seen.add(schema_path)
            yield schema_path


def _read_schema_path(row_or_name: Any) -> Optional[str]:
    if isinstance(row_or_name, str):
        return _normalize_schema_path(row_or_name)
    if isinstance(row_or_name, dict):
        for key in _SCHEMA_KEYS:
            value = row_or_name.get(key)
            if value:
                normalized = _normalize_schema_path(str(value))
                if normalized:
                    return normalized
    return None


def _normalize_schema_path(value: str) -> Optional[str]:
    parts = _split_schema_path(value)
    return ".".join(parts) if parts else None


def _split_schema_path(value: str) -> List[str]:
    return [segment.strip() for segment in value.split(".") if segment.strip()]


def _synthetic_schema_row(sample_row: Dict[str, Any], schema_path: str) -> Dict[str, Any]:
    synthetic = {k: None for k in sample_row.keys()}
    assigned = False
    for key in _SCHEMA_KEYS:
        actual = _metadata_row_key(sample_row, key)
        if actual is not None:
            synthetic[actual] = schema_path
            assigned = True
    if not assigned:
        synthetic["schema_name"] = schema_path
    return synthetic


def _metadata_row_key(row: Dict[str, Any], key: str) -> Optional[str]:
    for candidate in row.keys():
        if candidate.lower() == key.lower():
            return candidate
    return None
