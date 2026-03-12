# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""SQLAlchemy dialect for ScratchBird (SBWP v1.1)."""

from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional

from sqlalchemy import text, types
from sqlalchemy.engine.default import DefaultDialect


_CONNECT_ARG_ALIASES = {
    "applicationName": "application_name",
    "currentSchema": "schema",
    "searchPath": "search_path",
    "sslRootCert": "sslrootcert",
    "sslCert": "sslcert",
    "sslKey": "sslkey",
    "managerAuthToken": "manager_auth_token",
}


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
    "ARRAY": types.ARRAY(types.String()),
    "VECTOR": types.ARRAY(types.Float()),
    "GEOMETRY": types.LargeBinary(),
    "GEOGRAPHY": types.LargeBinary(),
    "COMPOSITE": types.String(),
    "RECORD": types.String(),
    "ROW": types.String(),
    "RANGE": types.String(),
    "TSVECTOR": types.Text(),
    "TSQUERY": types.Text(),
    "INET": types.String(),
    "CIDR": types.String(),
    "MACADDR": types.String(),
    "BIT": types.LargeBinary(),
    "BIT VARYING": types.LargeBinary(),
    "XML": types.Text(),
    "INTERVAL": types.String(),
    "MONEY": types.Numeric(),
    "UNKNOWN": types.LargeBinary(),
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
    if normalized.endswith("[]"):
        return types.ARRAY(_map_type(normalized[:-2]))
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

    def get_default_schema_name(self, connection):
        try:
            result = connection.exec_driver_sql("SHOW current_schema")
            row = result.fetchone()
            if row:
                for value in row:
                    if value:
                        return str(value)
        except Exception:
            pass
        return "users.public"

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
                if str(value).lower() in {"false", "0", "no", "off"}:
                    raise ValueError("binary_transfer=false is not supported")
                connect_args["binary_transfer"] = value
            else:
                mapped_key = _CONNECT_ARG_ALIASES.get(key, key)
                if mapped_key == "schema" and "schema" in connect_args:
                    continue
                connect_args[mapped_key] = value

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
        params: Dict[str, Any] = {"table": table_name}
        sql = (
            "SELECT c.column_name, c.data_type_name, c.is_nullable, c.default_value "
            "FROM sys.columns c "
            "JOIN sys.tables t ON t.table_id = c.table_id "
            "JOIN sys.schemas s ON s.schema_id = t.schema_id "
            "WHERE c.is_valid = 1 AND t.is_valid = 1 AND t.table_name = :table"
        )
        if schema:
            sql += " AND s.schema_name = :schema"
            params["schema"] = schema
        sql += " ORDER BY c.ordinal_position"
        rows = connection.execute(text(sql), params).fetchall()
        columns = []
        for row in rows:
            col_name = row[0]
            data_type_name = row[1]
            nullable = bool(row[2]) if row[2] is not None else True
            default_value = row[3]
            sqltype = _map_type(str(data_type_name))
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
        sql = (
            "SELECT kcu.column_name, tc.constraint_name "
            "FROM information_schema.table_constraints tc "
            "JOIN information_schema.key_column_usage kcu "
            "  ON tc.constraint_name = kcu.constraint_name "
            " AND tc.table_schema = kcu.table_schema "
            " AND tc.table_name = kcu.table_name "
            "WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_name = :table"
        )
        params: Dict[str, Any] = {"table": table_name}
        if schema:
            sql += " AND tc.table_schema = :schema"
            params["schema"] = schema
        sql += " ORDER BY kcu.ordinal_position"
        try:
            rows = connection.execute(text(sql), params).fetchall()
        except Exception:
            return {"constrained_columns": [], "name": None}
        columns = [row[0] for row in rows]
        name = rows[0][1] if rows else None
        return {"constrained_columns": columns, "name": name}

    def get_foreign_keys(self, connection, table_name: str, schema: Optional[str] = None, **kw):
        sql = (
            "SELECT tc.constraint_name, kcu.column_name, "
            "ccu.table_schema, ccu.table_name, ccu.column_name, "
            "rc.update_rule, rc.delete_rule "
            "FROM information_schema.table_constraints tc "
            "JOIN information_schema.key_column_usage kcu "
            "  ON tc.constraint_name = kcu.constraint_name "
            " AND tc.table_schema = kcu.table_schema "
            " AND tc.table_name = kcu.table_name "
            "JOIN information_schema.constraint_column_usage ccu "
            "  ON ccu.constraint_name = tc.constraint_name "
            " AND ccu.constraint_schema = tc.table_schema "
            "LEFT JOIN information_schema.referential_constraints rc "
            "  ON rc.constraint_name = tc.constraint_name "
            " AND rc.constraint_schema = tc.table_schema "
            "WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = :table"
        )
        params: Dict[str, Any] = {"table": table_name}
        if schema:
            sql += " AND tc.table_schema = :schema"
            params["schema"] = schema
        sql += " ORDER BY kcu.ordinal_position"
        try:
            rows = connection.execute(text(sql), params).fetchall()
        except Exception:
            return []
        keys: Dict[str, Dict[str, Any]] = {}
        for row in rows:
            name = row[0]
            fk_col = row[1]
            pk_schema = row[2]
            pk_table = row[3]
            pk_col = row[4]
            on_update = row[5]
            on_delete = row[6]
            entry = keys.setdefault(
                name,
                {
                    "name": name,
                    "constrained_columns": [],
                    "referred_schema": pk_schema,
                    "referred_table": pk_table,
                    "referred_columns": [],
                    "options": {},
                },
            )
            entry["constrained_columns"].append(fk_col)
            entry["referred_columns"].append(pk_col)
            if on_update:
                entry["options"]["onupdate"] = on_update
            if on_delete:
                entry["options"]["ondelete"] = on_delete
        return list(keys.values())

    def get_indexes(self, connection, table_name: str, schema: Optional[str] = None, **kw):
        sql = (
            "SELECT i.index_name, i.is_unique, c.column_name, ic.ordinal_position "
            "FROM sys.indexes i "
            "JOIN sys.tables t ON t.table_id = i.table_id "
            "JOIN sys.schemas s ON s.schema_id = t.schema_id "
            "LEFT JOIN sys.index_columns ic ON ic.index_id = i.index_id "
            "LEFT JOIN sys.columns c ON c.column_id = ic.column_id "
            "WHERE t.table_name = :table AND i.is_valid = 1"
        )
        params: Dict[str, Any] = {"table": table_name}
        if schema:
            sql += " AND s.schema_name = :schema"
            params["schema"] = schema
        sql += " ORDER BY i.index_name, ic.ordinal_position"
        try:
            rows = connection.execute(text(sql), params).fetchall()
        except Exception:
            return []
        indexes_by_name: Dict[str, Dict[str, Any]] = {}
        for row in rows:
            entry = indexes_by_name.setdefault(
                row[0],
                {
                    "name": row[0],
                    "column_names": [],
                    "unique": bool(row[1]),
                },
            )
            if row[2] is not None:
                entry["column_names"].append(row[2])
        return list(indexes_by_name.values())
