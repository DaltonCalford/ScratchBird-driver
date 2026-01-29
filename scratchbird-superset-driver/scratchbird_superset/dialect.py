"""SQLAlchemy dialect for ScratchBird (SBWP v1.1)."""

from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional

from sqlalchemy import text, types
from sqlalchemy.engine.default import DefaultDialect


_TYPE_MAP = {
    "BOOLEAN": types.Boolean(),
    "SMALLINT": types.SmallInteger(),
    "INTEGER": types.Integer(),
    "INT": types.Integer(),
    "BIGINT": types.BigInteger(),
    "INT8": types.BigInteger(),
    "REAL": types.Float(),
    "FLOAT": types.Float(),
    "DOUBLE": types.Float(),
    "DOUBLE PRECISION": types.Float(),
    "NUMERIC": types.Numeric(),
    "DECIMAL": types.Numeric(),
    "CHAR": types.String(),
    "CHARACTER": types.String(),
    "VARCHAR": types.String(),
    "CHARACTER VARYING": types.String(),
    "TEXT": types.Text(),
    "DATE": types.Date(),
    "TIME": types.Time(),
    "TIME WITH TIME ZONE": types.Time(timezone=True),
    "TIME WITHOUT TIME ZONE": types.Time(),
    "TIMESTAMP": types.DateTime(),
    "TIMESTAMPTZ": types.DateTime(timezone=True),
    "TIMESTAMP WITH TIME ZONE": types.DateTime(timezone=True),
    "TIMESTAMP WITHOUT TIME ZONE": types.DateTime(),
    "UUID": types.Uuid(),
    "JSON": types.JSON(),
    "JSONB": types.JSON(),
    "BYTEA": types.LargeBinary(),
    "BLOB": types.LargeBinary(),
}


def _normalize_type(type_name: Optional[str]) -> str:
    if not type_name:
        return ""
    normalized = type_name.strip().upper().replace("\t", " ").replace("\n", " ")
    while "  " in normalized:
        normalized = normalized.replace("  ", " ")
    if "(" in normalized:
        normalized = normalized.split("(", 1)[0].strip()
    return normalized


def _map_type(type_name: Optional[str]) -> types.TypeEngine:
    normalized = _normalize_type(type_name)
    mapped = _TYPE_MAP.get(normalized)
    if mapped is not None:
        return mapped
    return types.String()


class ScratchBirdDialect(DefaultDialect):
    name = "scratchbird"
    driver = "sbwp"
    paramstyle = "named"
    supports_statement_cache = True
    supports_sane_rowcount = True
    supports_sane_multi_rowcount = False
    supports_native_boolean = True
    supports_native_decimal = True
    supports_native_uuid = True

    @classmethod
    def dbapi(cls):
        import scratchbird

        return scratchbird

    def create_connect_args(self, url):
        connect_args: Dict[str, Any] = {}
        connect_args["host"] = url.host or "localhost"
        connect_args["port"] = int(url.port or 3092)
        if url.username:
            connect_args["user"] = url.username
        if url.password:
            connect_args["password"] = url.password
        if url.database:
            connect_args["database"] = url.database

        for key, value in url.query.items():
            if key == "connectTimeout":
                connect_args["connect_timeout"] = value
            elif key == "socketTimeout":
                connect_args["socket_timeout"] = value
            elif key == "binaryTransfer":
                connect_args["binary_transfer"] = value
            else:
                connect_args[key] = value

        return [], connect_args

    def get_schema_names(self, connection, **kw):
        rows = connection.exec_driver_sql(
            "SELECT schema_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
        ).fetchall()
        return [row[0] for row in rows]

    def get_table_names(self, connection, schema: Optional[str] = None, **kw):
        sql = (
            "SELECT t.table_name "
            "FROM sys.tables t "
            "JOIN sys.schemas s ON s.schema_id = t.schema_id "
            "WHERE t.is_valid = 1"
        )
        params: Dict[str, Any] = {}
        if schema:
            sql += " AND s.schema_name = :schema"
            params["schema"] = schema
        sql += " ORDER BY t.table_name"
        rows = connection.execute(text(sql), params).fetchall()
        return [row[0] for row in rows]

    def get_view_names(self, connection, schema: Optional[str] = None, **kw):
        sql = (
            "SELECT t.table_name "
            "FROM sys.tables t "
            "JOIN sys.schemas s ON s.schema_id = t.schema_id "
            "WHERE t.is_valid = 1 AND t.table_type = 'VIEW'"
        )
        params: Dict[str, Any] = {}
        if schema:
            sql += " AND s.schema_name = :schema"
            params["schema"] = schema
        sql += " ORDER BY t.table_name"
        try:
            rows = connection.execute(text(sql), params).fetchall()
        except Exception:
            return []
        return [row[0] for row in rows]

    def get_columns(self, connection, table_name: str, schema: Optional[str] = None, **kw):
        sql = (
            "SELECT c.column_name, c.data_type_id, c.is_nullable, c.default_value "
            "FROM sys.columns c "
            "JOIN sys.tables t ON t.table_id = c.table_id "
            "JOIN sys.schemas s ON s.schema_id = t.schema_id "
            "WHERE c.is_valid = 1 AND t.is_valid = 1 AND t.table_name = :table"
        )
        params: Dict[str, Any] = {"table": table_name}
        if schema:
            sql += " AND s.schema_name = :schema"
            params["schema"] = schema
        sql += " ORDER BY c.ordinal_position"

        rows = connection.execute(text(sql), params).fetchall()
        columns = []
        for row in rows:
            col_name = row[0]
            data_type_id = row[1]
            nullable = bool(row[2]) if row[2] is not None else True
            default_value = row[3]
            sqltype = _map_type(str(data_type_id))
            columns.append(
                {
                    "name": col_name,
                    "type": sqltype,
                    "nullable": nullable,
                    "default": default_value,
                }
            )
        return columns

    def get_pk_constraint(self, connection, table_name: str, schema: Optional[str] = None, **kw):
        return {"constrained_columns": [], "name": None}

    def get_foreign_keys(self, connection, table_name: str, schema: Optional[str] = None, **kw):
        return []

    def get_indexes(self, connection, table_name: str, schema: Optional[str] = None, **kw):
        return []
