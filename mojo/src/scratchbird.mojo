# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import urllib.parse

try:
    import scratchbird as _sb
    from scratchbird import dsn as _dsn
except Exception as exc:
    raise RuntimeError("Python scratchbird driver is required for the Mojo adapter") from exc


class ScratchBirdConfig:
    def __init__(self, dsn: str = ""):
        self.dsn = dsn or ""
        self.host = "localhost"
        self.port = 3092
        self.database = ""
        self.user = ""
        self.password = ""
        self.sslmode = "require"
        self.sslrootcert = ""
        self.sslcert = ""
        self.sslkey = ""
        self.sslpassword = ""
        self.connect_timeout_ms = 0
        self.socket_timeout_ms = 0
        self.application_name = ""
        self.search_path = ""
        self.role = ""
        self.binary_transfer = True
        self.compression = "off"
        self.fetch_size = 0

        if self.dsn:
            self._apply_params(_dsn.parse_dsn(self.dsn))

    def _apply_params(self, params):
        def _as_bool(value):
            if isinstance(value, bool):
                return value
            return str(value).lower() in ("1", "true", "yes", "on")

        if "host" in params:
            self.host = params["host"]
        if "port" in params:
            try:
                self.port = int(params["port"])
            except Exception:
                pass
        if "database" in params:
            self.database = params["database"]
        if "dbname" in params and not self.database:
            self.database = params["dbname"]
        if "user" in params:
            self.user = params["user"]
        if "username" in params and not self.user:
            self.user = params["username"]
        if "password" in params:
            self.password = params["password"]
        if "sslmode" in params:
            self.sslmode = params["sslmode"]
        if "sslrootcert" in params:
            self.sslrootcert = params["sslrootcert"]
        if "sslcert" in params:
            self.sslcert = params["sslcert"]
        if "sslkey" in params:
            self.sslkey = params["sslkey"]
        if "sslpassword" in params:
            self.sslpassword = params["sslpassword"]
        if "connect_timeout" in params:
            try:
                self.connect_timeout_ms = int(float(params["connect_timeout"]) * 1000)
            except Exception:
                pass
        if "socket_timeout" in params:
            try:
                self.socket_timeout_ms = int(float(params["socket_timeout"]) * 1000)
            except Exception:
                pass
        if "application_name" in params:
            self.application_name = params["application_name"]
        if "search_path" in params:
            self.search_path = params["search_path"]
        if "role" in params:
            self.role = params["role"]
        if "binary_transfer" in params:
            self.binary_transfer = _as_bool(params["binary_transfer"])
        if "compression" in params:
            self.compression = params["compression"]
        if "fetch_size" in params:
            try:
                self.fetch_size = int(params["fetch_size"])
            except Exception:
                pass

    def to_dsn(self) -> str:
        if self.dsn:
            return self.dsn

        userinfo = ""
        if self.user:
            userinfo = urllib.parse.quote(self.user)
            if self.password:
                userinfo = userinfo + ":" + urllib.parse.quote(self.password)
            userinfo = userinfo + "@"

        params = {}
        if self.sslmode:
            params["sslmode"] = self.sslmode
        if self.sslrootcert:
            params["sslrootcert"] = self.sslrootcert
        if self.sslcert:
            params["sslcert"] = self.sslcert
        if self.sslkey:
            params["sslkey"] = self.sslkey
        if self.sslpassword:
            params["sslpassword"] = self.sslpassword
        if self.connect_timeout_ms:
            params["connect_timeout"] = str(int(self.connect_timeout_ms / 1000))
        if self.socket_timeout_ms:
            params["socket_timeout"] = str(int(self.socket_timeout_ms / 1000))
        if self.application_name:
            params["application_name"] = self.application_name
        if self.search_path:
            params["search_path"] = self.search_path
        if self.role:
            params["role"] = self.role
        if self.binary_transfer is not None:
            params["binary_transfer"] = "true" if self.binary_transfer else "false"
        if self.compression:
            params["compression"] = self.compression
        if self.fetch_size:
            params["fetch_size"] = str(self.fetch_size)

        query = urllib.parse.urlencode(params) if params else ""
        host = self.host or "localhost"
        port = self.port or 3092
        path = "/" + self.database if self.database else ""
        dsn = f"scratchbird://{userinfo}{host}:{port}{path}"
        if query:
            dsn = dsn + "?" + query
        return dsn


class ScratchBirdColumn:
    def __init__(self, name: str, type_oid: int, format: int = 1):
        self.name = name
        self.type_oid = type_oid
        self.format = format


class ScratchBirdResult:
    def __init__(self, rows, columns, rowcount):
        self.rows = rows
        self.columns = columns
        self.rowcount = rowcount


class QueryPlanMessage:
    def __init__(self, plan_tuple):
        self.format = plan_tuple[0]
        self.planning_time_us = plan_tuple[1]
        self.estimated_rows = plan_tuple[2]
        self.estimated_cost = plan_tuple[3]
        self.plan = plan_tuple[4]


class SblrCompiledMessage:
    def __init__(self, sblr_tuple):
        self.hash = sblr_tuple[0]
        self.version = sblr_tuple[1]
        self.bytecode = sblr_tuple[2]


class NotificationMessage:
    def __init__(self, notice_tuple):
        self.process_id = notice_tuple[0]
        self.channel = notice_tuple[1]
        self.payload = notice_tuple[2]
        self.change_type = notice_tuple[3]
        self.row_id = notice_tuple[4]


class ScratchBirdStatement:
    def __init__(self, connection, sql: str):
        self._connection = connection
        self._sql = sql

    def execute(self, params=None):
        return self._connection.query(self._sql, params)


class ScratchBirdConnection:
    def __init__(self, config: ScratchBirdConfig):
        self.config = config
        self._conn = None
        self._notification_handlers = []

    def connect(self):
        if self._conn is not None:
            return
        if not self.config.binary_transfer:
            raise RuntimeError("binary_transfer=false is not supported")
        if self.config.compression == "zstd":
            raise RuntimeError("compression=zstd is not supported")
        if self.config.sslmode == "disable":
            raise RuntimeError("TLS is required for ScratchBird connections")
        self._conn = _sb.connect(self.config.to_dsn())
        self._conn.on_notification(self._handle_notification)

    def close(self):
        if self._conn is None:
            return
        self._conn.close()
        self._conn = None

    def terminate(self):
        self.close()

    def query(self, sql: str, params=None) -> ScratchBirdResult:
        self._ensure_open()
        cursor = self._conn.execute(sql, params)
        rows = cursor.fetchall()
        columns = []
        if cursor.description:
            for entry in cursor.description:
                name = entry[0]
                type_oid = entry[1] if entry[1] is not None else 0
                columns.append(ScratchBirdColumn(name, type_oid))
        return ScratchBirdResult(rows, columns, cursor.rowcount)

    def stream(self, sql: str, params=None):
        self._ensure_open()
        cursor = self._conn.cursor()
        cursor.execute(sql, params)
        return cursor

    def prepare(self, sql: str) -> ScratchBirdStatement:
        self._ensure_open()
        return ScratchBirdStatement(self, sql)

    def transaction(self, fn):
        self.begin()
        try:
            result = fn(self)
        except Exception:
            self.rollback()
            raise
        self.commit()
        return result

    def begin(self, **kwargs):
        self._ensure_open()
        self._conn.begin(**kwargs)

    def commit(self, flags: int = 0):
        self._ensure_open()
        self._conn.commit(flags)

    def rollback(self, flags: int = 0):
        self._ensure_open()
        self._conn.rollback(flags)

    def savepoint(self, name: str):
        self._ensure_open()
        self._conn.savepoint(name)

    def release_savepoint(self, name: str):
        self._ensure_open()
        self._conn.release_savepoint(name)

    def rollback_to_savepoint(self, name: str):
        self._ensure_open()
        self._conn.rollback_to_savepoint(name)

    def set_option(self, name: str, value: str):
        self._ensure_open()
        self._conn.set_option(name, value)

    def ping(self):
        self._ensure_open()
        self._conn.ping()

    def subscribe(self, channel: str, sub_type: int = 0, filter_expr: str = ""):
        self._ensure_open()
        self._conn.subscribe(channel, sub_type, filter_expr)

    def unsubscribe(self, channel: str):
        self._ensure_open()
        self._conn.unsubscribe(channel)

    def execute_sblr(self, sblr_hash: int, sblr_bytecode=None, params=None):
        self._ensure_open()
        return self._conn.execute_sblr(sblr_hash, sblr_bytecode, params)

    def stream_control(self, control_type: int, window_size: int, timeout_ms: int):
        self._ensure_open()
        self._conn.stream_control(control_type, window_size, timeout_ms)

    def attach_create(self, emulation_mode: str, db_name: str):
        self._ensure_open()
        self._conn.attach_create(emulation_mode, db_name)

    def attach_detach(self):
        self._ensure_open()
        self._conn.attach_detach()

    def attach_list(self):
        self._ensure_open()
        return self._conn.attach_list()

    def cancel(self):
        self._ensure_open()
        self._conn.cancel()

    def on_notification(self, handler):
        self._notification_handlers.append(handler)

    def last_query_plan(self):
        self._ensure_open()
        plan = self._conn.last_plan()
        if plan is None:
            return None
        return QueryPlanMessage(plan)

    def last_sblr_compiled(self):
        self._ensure_open()
        sblr = self._conn.last_sblr()
        if sblr is None:
            return None
        return SblrCompiledMessage(sblr)

    def _handle_notification(self, notice):
        msg = NotificationMessage(notice)
        for handler in self._notification_handlers:
            handler(msg)

    def _ensure_open(self):
        if self._conn is None:
            raise RuntimeError("connection is closed")


def connect(config: ScratchBirdConfig) -> ScratchBirdConnection:
    conn = ScratchBirdConnection(config)
    conn.connect()
    return conn


# Metadata helpers (sys.*) per METADATA_SCHEMA_CONTRACT.md.
METADATA_SCHEMAS_QUERY = "SELECT schema_id, schema_name, owner_id, default_tablespace_id FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
METADATA_TABLES_QUERY = "SELECT table_id, schema_id, table_name, table_type, owner_id FROM sys.tables WHERE is_valid = 1 ORDER BY table_name"
METADATA_COLUMNS_QUERY = "SELECT column_id, table_id, column_name, data_type_id, data_type_name, ordinal_position, is_nullable, default_value, domain_id, collation_id, charset_id, is_identity, is_generated, generation_expression FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
METADATA_INDEXES_QUERY = "SELECT index_id, table_id, index_name, index_type, is_unique FROM sys.indexes WHERE is_valid = 1 ORDER BY table_id, index_name"
METADATA_INDEX_COLUMNS_QUERY = "SELECT index_id, column_id, column_name, ordinal_position, is_included FROM sys.index_columns ORDER BY index_id, ordinal_position"
METADATA_CONSTRAINTS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 ORDER BY table_id, constraint_name"
METADATA_PROCEDURES_QUERY = "SELECT procedure_id, schema_id, procedure_name, routine_type FROM sys.procedures WHERE is_valid = 1 ORDER BY schema_id, procedure_name"
METADATA_FUNCTIONS_QUERY = "SELECT function_id, schema_id, function_name FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, function_name"
