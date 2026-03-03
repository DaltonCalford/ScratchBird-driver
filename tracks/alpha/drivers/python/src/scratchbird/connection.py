# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""Connection implementation for ScratchBird Python driver (SBWP v1.1)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional

import socket
import ssl
import os
import struct

from . import errors
from .circuit_breaker import CircuitBreaker, CircuitBreakerConfig, CircuitBreakerError
from .keepalive import KeepaliveManager, KeepaliveConfig
from .leak_detection import LeakDetector, LeakDetectionConfig
from .telemetry import TelemetryCollector, TelemetryConfig
from .dsn import parse_dsn, normalize_front_door_mode, normalize_native_protocol
from .cursor import Cursor
from .protocol import (
    AuthMethod,
    MessageType,
    MSG_FLAG_URGENT,
    FEATURE_COMPRESSION,
    FEATURE_STREAMING,
    FEATURE_BINARY_COPY,
    QUERY_FLAG_DESCRIBE_ONLY,
    QUERY_FLAG_INCLUDE_PLAN,
    QUERY_FLAG_RETURN_SBLR,
    QUERY_FLAG_NO_CACHE,
    ISOLATION_READ_COMMITTED,
    TXN_FLAG_HAS_ACCESS,
    TXN_FLAG_HAS_AUTOCOMMIT,
    TXN_FLAG_HAS_DEFERRABLE,
    TXN_FLAG_HAS_ISOLATION,
    TXN_FLAG_HAS_TIMEOUT,
    TXN_FLAG_HAS_WAIT,
    COPY_FORMAT_TEXT,
    COPY_FORMAT_BINARY,
    HEADER_SIZE,
    MessageHeader,
    build_bind_payload,
    build_cancel_payload,
    build_describe_payload,
    build_execute_payload,
    build_parse_payload,
    build_query_payload,
    build_sblr_execute_payload,
    build_subscribe_payload,
    build_unsubscribe_payload,
    build_txn_begin_payload,
    build_txn_commit_payload,
    build_txn_rollback_payload,
    build_txn_savepoint_payload,
    build_txn_release_payload,
    build_txn_rollback_to_payload,
    build_set_option_payload,
    build_stream_control_payload,
    build_attach_create_payload,
    build_startup_payload,
    AUTH_PARAM_METHOD_ID,
    AUTH_PARAM_PAYLOAD_JSON,
    AUTH_PARAM_PAYLOAD_B64,
    AUTH_PARAM_PROVIDER_PROFILE,
    AuthPluginSelection,
    apply_auth_plugin_selection,
    build_copy_data_payload,
    build_copy_done_payload,
    build_copy_fail_payload,
    parse_auth_continue,
    parse_auth_ok,
    parse_auth_request,
    parse_command_complete,
    parse_copy_in_response,
    parse_copy_out_response,
    parse_data_row,
    parse_error_message,
    parse_notification,
    parse_query_plan,
    parse_sblr_compiled,
    parse_parameter_description,
    parse_parameter_status,
    parse_ready,
    parse_row_description,
)
from .scram import ScramExchange
from .sql import normalize_query
from .metadata import normalize_collection_name, resolve_collection_query
from .types import FORMAT_BINARY, decode_value, encode_param

MANAGER_PROTOCOL_MAGIC = 0x42444253  # SBDB
MANAGER_PROTOCOL_VERSION = 0x0101
MANAGER_HEADER_SIZE = 12
MANAGER_MAX_PAYLOAD_SIZE = 16 * 1024 * 1024
MCP_PROTOCOL_VERSION = 0x0100

MCP_MSG_CONNECT_RESPONSE = 0x02
MCP_MSG_AUTH_CHALLENGE = 0x12
MCP_MSG_AUTH_RESPONSE = 0x11
MCP_MSG_STATUS_RESPONSE = 0x64
MCP_MSG_HELLO = 0x65
MCP_MSG_AUTH_START = 0x66
MCP_MSG_AUTH_CONTINUE = 0x67
MCP_MSG_DB_CONNECT = 0x69
MCP_AUTH_METHOD_TOKEN = 4


@dataclass
class ConnectionConfig:
    host: str = "localhost"
    port: int = 3092
    front_door_mode: str = "direct"
    protocol: str = "native"
    database: Optional[str] = None
    user: Optional[str] = None
    password: Optional[str] = None
    schema: Optional[str] = None
    metadata_expand_schema_parents: bool = False
    sslmode: str = "require"
    sslrootcert: Optional[str] = None
    sslcert: Optional[str] = None
    sslkey: Optional[str] = None
    sslpassword: Optional[str] = None
    connect_timeout: int = 30
    socket_timeout: int = 0
    application_name: Optional[str] = None
    role: Optional[str] = None
    binary_transfer: bool = True
    compression: str = "off"
    manager_auth_token: Optional[str] = None
    manager_username: Optional[str] = None
    manager_database: Optional[str] = None
    manager_connection_profile: str = "native_v3"
    manager_client_intent: str = "native_v3"
    manager_client_flags: int = 0
    manager_auth_fast_path: bool = True
    auth_method_id: Optional[str] = None
    auth_payload_json: Optional[str] = None
    auth_payload_b64: Optional[str] = None
    auth_provider_profile: Optional[str] = None
    extra: Dict[str, Any] = field(default_factory=dict)


def connect(dsn=None, user=None, password=None, host=None, database=None, **kwargs):
    params = {}
    params.update(parse_dsn(dsn))

    for key, value in kwargs.items():
        params[key] = value

    if user is not None:
        params["user"] = user
    if password is not None:
        params["password"] = password
    if host is not None:
        params["host"] = host
    if database is not None:
        params["database"] = database

    cfg = ConnectionConfig()
    cfg.host = params.get("host", cfg.host)
    cfg.port = int(params.get("port", cfg.port))
    try:
        cfg.protocol = normalize_native_protocol(params.get("protocol", params.get("parser", params.get("dialect"))))
        cfg.front_door_mode = normalize_front_door_mode(
            params.get(
                "front_door_mode",
                params.get(
                    "frontdoormode",
                    params.get("frontDoorMode", params.get("connection_mode", params.get("ingress_mode"))),
                ),
            )
        )
    except ValueError as exc:
        raise errors.InterfaceError(str(exc)) from exc
    cfg.database = params.get("database", params.get("dbname", cfg.database))
    cfg.user = params.get("user", params.get("username", cfg.user))
    cfg.password = params.get("password", cfg.password)
    cfg.schema = params.get("schema", params.get("search_path", params.get("searchpath", params.get("currentschema", cfg.schema))))
    raw_expand_schema_parents = params.get(
        "metadata_expand_schema_parents",
        params.get(
            "metadataexpandschemaparents",
            params.get(
                "metadataExpandSchemaParents",
                params.get(
                    "expandschemaparents",
                    params.get(
                        "expand_schema_parents",
                        params.get(
                            "dbeaverexpandschemaparents",
                            params.get("dbeaver_expand_schema_parents", cfg.metadata_expand_schema_parents),
                        ),
                    ),
                ),
            ),
        ),
    )
    if isinstance(raw_expand_schema_parents, str):
        cfg.metadata_expand_schema_parents = raw_expand_schema_parents.lower() in ("1", "true", "yes", "on")
    else:
        cfg.metadata_expand_schema_parents = bool(raw_expand_schema_parents)
    cfg.sslmode = params.get("sslmode", params.get("ssl", cfg.sslmode))
    cfg.sslrootcert = params.get("sslrootcert", cfg.sslrootcert)
    cfg.sslcert = params.get("sslcert", cfg.sslcert)
    cfg.sslkey = params.get("sslkey", cfg.sslkey)
    cfg.sslpassword = params.get("sslpassword", cfg.sslpassword)
    cfg.connect_timeout = int(params.get("connect_timeout", params.get("connecttimeout", cfg.connect_timeout)))
    cfg.socket_timeout = int(params.get("socket_timeout", params.get("sockettimeout", cfg.socket_timeout)))
    cfg.application_name = params.get("application_name", params.get("applicationname", cfg.application_name))
    cfg.role = params.get("role", cfg.role)
    raw_binary = params.get("binary_transfer", params.get("binarytransfer", cfg.binary_transfer))
    if isinstance(raw_binary, str):
        cfg.binary_transfer = raw_binary.lower() in ("1", "true", "yes", "on")
    else:
        cfg.binary_transfer = bool(raw_binary)
    cfg.compression = params.get("compression", cfg.compression) or "off"
    cfg.manager_auth_token = params.get("manager_auth_token", params.get("mcp_auth_token", cfg.manager_auth_token))
    cfg.manager_username = params.get("manager_username", params.get("mcp_username", cfg.manager_username))
    cfg.manager_database = params.get("manager_database", params.get("mcp_database", cfg.manager_database))
    cfg.manager_connection_profile = params.get(
        "manager_connection_profile", params.get("mcp_connection_profile", cfg.manager_connection_profile)
    ) or "native_v3"
    cfg.manager_client_intent = params.get(
        "manager_client_intent", params.get("mcp_client_intent", cfg.manager_client_intent)
    ) or "native_v3"
    raw_manager_flags = params.get("manager_client_flags", params.get("mcp_client_flags"))
    if raw_manager_flags is not None:
        try:
            cfg.manager_client_flags = int(raw_manager_flags)
        except ValueError:
            cfg.manager_client_flags = 0
    raw_fast_path = params.get("manager_auth_fast_path", params.get("mcp_auth_fast_path"))
    if raw_fast_path is not None:
        if isinstance(raw_fast_path, str):
            cfg.manager_auth_fast_path = raw_fast_path.lower() in ("1", "true", "yes", "on")
        else:
            cfg.manager_auth_fast_path = bool(raw_fast_path)
    cfg.auth_method_id = params.get(AUTH_PARAM_METHOD_ID, params.get("authmethodid", cfg.auth_method_id))
    cfg.auth_payload_json = params.get(AUTH_PARAM_PAYLOAD_JSON, params.get("authpayloadjson", cfg.auth_payload_json))
    cfg.auth_payload_b64 = params.get(AUTH_PARAM_PAYLOAD_B64, params.get("authpayloadb64", cfg.auth_payload_b64))
    cfg.auth_provider_profile = params.get(
        AUTH_PARAM_PROVIDER_PROFILE,
        params.get("authproviderprofile", cfg.auth_provider_profile),
    )
    cfg.extra = {
        k: v
        for k, v in params.items()
        if k not in {
            "host",
            "port",
            "front_door_mode",
            "frontdoormode",
            "frontDoorMode",
            "connection_mode",
            "ingress_mode",
            "database",
            "dbname",
            "protocol",
            "parser",
            "dialect",
            "user",
            "username",
            "password",
            "schema",
            "search_path",
            "searchpath",
            "currentschema",
            "metadata_expand_schema_parents",
            "metadataexpandschemaparents",
            "metadataExpandSchemaParents",
            "expandschemaparents",
            "expand_schema_parents",
            "dbeaverexpandschemaparents",
            "dbeaver_expand_schema_parents",
            "sslmode",
            "ssl",
            "sslrootcert",
            "sslcert",
            "sslkey",
            "sslpassword",
            "connect_timeout",
            "connecttimeout",
            "socket_timeout",
            "sockettimeout",
            "application_name",
            "applicationname",
            "role",
            "binary_transfer",
            "binarytransfer",
            "compression",
            "manager_auth_token",
            "mcp_auth_token",
            "manager_username",
            "mcp_username",
            "manager_database",
            "mcp_database",
            "manager_connection_profile",
            "mcp_connection_profile",
            "manager_client_intent",
            "mcp_client_intent",
            "manager_client_flags",
            "mcp_client_flags",
            "manager_auth_fast_path",
            "mcp_auth_fast_path",
            AUTH_PARAM_METHOD_ID,
            "authmethodid",
            AUTH_PARAM_PAYLOAD_JSON,
            "authpayloadjson",
            AUTH_PARAM_PAYLOAD_B64,
            "authpayloadb64",
            AUTH_PARAM_PROVIDER_PROFILE,
            "authproviderprofile",
        }
    }

    return Connection(cfg)


class Connection:
    def __init__(self, config: ConnectionConfig):
        self._config = config
        self._closed = False
        self._cursors = []
        self._autocommit = True
        self._warnings = None
        self._socket = None
        self._connected = False
        self._sequence = 0
        self._attachment_id = b"\x00" * 16
        self._txn_id = 0
        self._authed = False
        self._parameters: Dict[str, str] = {}
        self._notification_handlers = []
        self._last_plan = None
        self._last_sblr = None
        self._conn_id = f"conn-{id(self)}"
        self._circuit_breaker = CircuitBreaker(CircuitBreakerConfig(), name=self._conn_id)
        self._telemetry = TelemetryCollector(TelemetryConfig())
        self._keepalive = KeepaliveManager(KeepaliveConfig())
        self._keepalive.start()
        self._leak_detector = LeakDetector(LeakDetectionConfig())
        self._leak_detector.start()
        self._leak_guard = self._leak_detector.checkout(self._conn_id, {"driver": "python"})
        self._connect()

    def _connect(self) -> None:
        try:
            self._config.protocol = normalize_native_protocol(self._config.protocol)
            self._config.front_door_mode = normalize_front_door_mode(self._config.front_door_mode)
        except ValueError as exc:
            raise errors.InterfaceError(str(exc)) from exc
        if not self._config.user or not self._config.database:
            raise errors.InterfaceError("user and database are required")
        if not self._config.binary_transfer:
            raise errors.NotSupportedError("binary_transfer=false is not supported")
        if (self._config.compression or "").lower() == "zstd":
            raise errors.NotSupportedError("compression=zstd is not supported")
        if self._config.front_door_mode == "manager_proxy" and not self._config.manager_auth_token:
            raise errors.InterfaceError("manager_proxy mode requires manager_auth_token")
        raw_sock = socket.create_connection(
            (self._config.host, self._config.port),
            timeout=self._config.connect_timeout,
        )
        raw_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        raw_sock.settimeout(self._config.socket_timeout or None)

        sslmode = (self._config.sslmode or "require").lower()
        if sslmode == "disable":
            raw_sock.close()
            raise errors.InterfaceError("TLS is required for ScratchBird connections")

        ctx = ssl.create_default_context()
        ctx.minimum_version = ssl.TLSVersion.TLSv1_3
        ctx.maximum_version = ssl.TLSVersion.TLSv1_3
        if sslmode in ("verify-ca", "verify-full"):
            ctx.check_hostname = sslmode == "verify-full"
            ctx.verify_mode = ssl.CERT_REQUIRED
        else:
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
        if self._config.sslrootcert:
            ctx.load_verify_locations(self._config.sslrootcert)
        if self._config.sslcert and self._config.sslkey:
            ctx.load_cert_chain(self._config.sslcert, self._config.sslkey, password=self._config.sslpassword)

        try:
            sock = ctx.wrap_socket(raw_sock, server_hostname=self._config.host)
        except ssl.SSLError:
            raw_sock.close()
            raise
        self._socket = sock

        if self._config.front_door_mode == "manager_proxy":
            self._perform_manager_connect()
        self._startup_and_auth()
        self._apply_schema()
        self._connected = True
        self._keepalive_tracker = self._keepalive.register(
            self._conn_id,
            self._ping_for_keepalive,
        )

    def _ping_for_keepalive(self) -> bool:
        try:
            self.ping()
            return True
        except Exception:
            return False

    def close(self) -> None:
        if not self._closed:
            self._closed = True
            self._connected = False
            try:
                if self._keepalive:
                    self._keepalive.unregister(self._conn_id)
                    self._keepalive.stop()
            except Exception:
                pass
            try:
                if self._leak_guard:
                    self._leak_guard.release()
                if self._leak_detector:
                    self._leak_detector.stop()
            except Exception:
                pass
            if self._socket:
                try:
                    self._socket.close()
                except OSError:
                    pass

    def _begin_operation(self, name: str, sql: Optional[str] = None):
        if self._circuit_breaker and not self._circuit_breaker.allow_request():
            raise CircuitBreakerError("circuit breaker is open")
        if getattr(self, "_keepalive_tracker", None):
            self._keepalive_tracker.mark_active()
        span = None
        if self._telemetry:
            span = self._telemetry.start_span(name)
            if span is not None and sql:
                sql_text = sql
                if self._telemetry.config.sanitize_queries:
                    sql_text = self._telemetry.sanitize_query(sql_text)
                span.with_attribute("sql", sql_text)
        return span

    def _end_operation(self, span, success: bool) -> None:
        if self._circuit_breaker:
            if success:
                self._circuit_breaker.record_success()
            else:
                self._circuit_breaker.record_failure()
        if self._telemetry and span is not None:
            self._telemetry.end_span(span, success=success)

    def commit(self) -> None:
        self._ensure_open()
        if not self._transaction_active():
            return
        payload = build_txn_commit_payload(0)
        self._send_message(MessageType.TXN_COMMIT, payload)
        self._drain_until_ready()

    def rollback(self) -> None:
        self._ensure_open()
        if not self._transaction_active():
            return
        payload = build_txn_rollback_payload(0)
        self._send_message(MessageType.TXN_ROLLBACK, payload)
        self._drain_until_ready()

    def begin(self, **kwargs) -> None:
        self._ensure_open()
        if self._transaction_active():
            raise errors.ProgrammingError("transaction already active")
        flags = 0
        isolation = kwargs.get("isolation_level", ISOLATION_READ_COMMITTED)
        if "isolation_level" in kwargs:
            flags |= TXN_FLAG_HAS_ISOLATION
        if "access_mode" in kwargs:
            flags |= TXN_FLAG_HAS_ACCESS
        if "deferrable" in kwargs:
            flags |= TXN_FLAG_HAS_DEFERRABLE
        if "wait" in kwargs:
            flags |= TXN_FLAG_HAS_WAIT
        if "timeout_ms" in kwargs:
            flags |= TXN_FLAG_HAS_TIMEOUT
        if "autocommit_mode" in kwargs:
            flags |= TXN_FLAG_HAS_AUTOCOMMIT
        payload = build_txn_begin_payload(
            flags,
            kwargs.get("conflict_action", 0),
            kwargs.get("autocommit_mode", 0),
            isolation,
            kwargs.get("access_mode", 0),
            1 if kwargs.get("deferrable") else 0,
            1 if kwargs.get("wait") else 0,
            kwargs.get("timeout_ms", 0),
        )
        self._send_message(MessageType.TXN_BEGIN, payload)
        self._drain_until_ready()

    def savepoint(self, name: str) -> None:
        self._ensure_open()
        if not self._transaction_active():
            raise errors.ProgrammingError("savepoint requires an active transaction")
        payload = build_txn_savepoint_payload(self._normalize_savepoint_name(name))
        self._send_message(MessageType.TXN_SAVEPOINT, payload)
        self._drain_until_ready()

    def release_savepoint(self, name: str) -> None:
        self._ensure_open()
        if not self._transaction_active():
            raise errors.ProgrammingError("release_savepoint requires an active transaction")
        payload = build_txn_release_payload(self._normalize_savepoint_name(name))
        self._send_message(MessageType.TXN_RELEASE, payload)
        self._drain_until_ready()

    def rollback_to_savepoint(self, name: str) -> None:
        self._ensure_open()
        if not self._transaction_active():
            raise errors.ProgrammingError("rollback_to_savepoint requires an active transaction")
        payload = build_txn_rollback_to_payload(self._normalize_savepoint_name(name))
        self._send_message(MessageType.TXN_ROLLBACK_TO, payload)
        self._drain_until_ready()

    def set_option(self, name: str, value: str) -> None:
        self._ensure_open()
        payload = build_set_option_payload(name, value)
        self._send_message(MessageType.SET_OPTION, payload)
        self._drain_until_ready()

    def ping(self) -> None:
        self._ensure_open()
        self._send_message(MessageType.PING, b"")
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.PONG:
                return
            if header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                return
            if header.msg_type == MessageType.ERROR:
                self._raise_protocol_error(payload)

    def subscribe(self, channel: str, sub_type: int = 0, filter_expr: str = "") -> None:
        self._ensure_open()
        payload = build_subscribe_payload(sub_type, channel, filter_expr)
        self._send_message(MessageType.SUBSCRIBE, payload)
        self._drain_until_ready()

    def unsubscribe(self, channel: str) -> None:
        self._ensure_open()
        payload = build_unsubscribe_payload(channel)
        self._send_message(MessageType.UNSUBSCRIBE, payload)
        self._drain_until_ready()

    def execute_sblr(self, sblr_hash: int, sblr_bytecode: Optional[bytes] = None, params=None):
        self._ensure_open()
        span = self._begin_operation("execute_sblr", "")
        param_values = []
        if params:
            for param in params:
                value, _ = encode_param(param)
                param_values.append(value)
        payload = build_sblr_execute_payload(sblr_hash, sblr_bytecode, param_values)
        try:
            self._send_message(MessageType.SBLR_EXECUTE, payload)
            self._send_message(MessageType.SYNC, b"")
            self._end_operation(span, True)
        except Exception:
            self._end_operation(span, False)
            raise
        return ResultStream(self, 0)

    def stream_control(self, control_type: int, window_size: int, timeout_ms: int) -> None:
        self._ensure_open()
        payload = build_stream_control_payload(control_type, window_size, timeout_ms)
        self._send_message(MessageType.STREAM_CONTROL, payload)

    def attach_create(self, emulation_mode: str, db_name: str) -> None:
        self._ensure_open()
        payload = build_attach_create_payload(emulation_mode, db_name)
        self._send_message(MessageType.ATTACH_CREATE, payload)
        self._drain_until_ready()

    def attach_detach(self) -> None:
        self._ensure_open()
        self._send_message(MessageType.ATTACH_DETACH, b"")
        self._drain_until_ready()

    def attach_list(self):
        self._ensure_open()
        self._send_message(MessageType.ATTACH_LIST, b"")
        self._send_message(MessageType.SYNC, b"")
        return ResultStream(self, 0)

    def on_notification(self, handler) -> None:
        self._notification_handlers.append(handler)

    def last_plan(self):
        return self._last_plan

    def last_sblr(self):
        return self._last_sblr

    def cursor(self) -> Cursor:
        self._ensure_open()
        cur = Cursor(self)
        self._cursors.append(cur)
        return cur

    def execute(self, sql: str, params=None) -> Cursor:
        cur = self.cursor()
        cur.execute(sql, params)
        return cur

    def native_sql(self, sql: str, params=None) -> str:
        self._ensure_open()
        if sql is None:
            raise errors.ProgrammingError("sql is required")
        try:
            normalized_sql, _ = normalize_query(sql, params)
        except ValueError as exc:
            raise errors.ProgrammingError(str(exc)) from exc
        return normalized_sql

    def executemany(self, sql: str, seq_of_params) -> Cursor:
        cur = self.cursor()
        cur.executemany(sql, seq_of_params)
        return cur

    def query_metadata(self, collection_name: str = "tables") -> Cursor:
        self._ensure_open()
        normalized_collection = self._normalize_metadata_collection(collection_name)
        metadata_sql = resolve_collection_query(normalized_collection)
        return self.execute(metadata_sql)

    def get_schema(self, collection_name: str = "tables"):
        cur = self.query_metadata(collection_name)
        return cur.fetchall()

    def setinputsizes(self, sizes) -> None:
        self._ensure_open()

    def setoutputsize(self, size, column=None) -> None:
        self._ensure_open()

    def _ensure_open(self) -> None:
        if self._closed:
            raise errors.InterfaceError("connection is closed")

    def _transaction_active(self) -> bool:
        return self._txn_id != 0

    def _normalize_savepoint_name(self, name: str) -> str:
        if not isinstance(name, str):
            raise errors.ProgrammingError("savepoint name must be a string")
        normalized = name.strip()
        if not normalized:
            raise errors.ProgrammingError("savepoint name is required")
        return normalized

    def _normalize_metadata_collection(self, collection_name: str) -> str:
        try:
            return normalize_collection_name(collection_name)
        except ValueError as exc:
            raise errors.NotSupportedError(str(exc)) from exc

    def _handle_async(self, header: MessageHeader, payload: bytes) -> bool:
        if header.msg_type == MessageType.PARAMETER_STATUS:
            name, value = parse_parameter_status(payload)
            self._parameters[name] = value
            if name == "attachment_id":
                parsed = _parse_uuid_bytes(value)
                if parsed is not None:
                    self._attachment_id = parsed
            if name == "current_txn_id":
                parsed = _parse_uint64(value)
                if parsed is not None:
                    self._txn_id = parsed
            return True
        if header.msg_type == MessageType.NOTIFICATION:
            notice = parse_notification(payload)
            for handler in self._notification_handlers:
                handler(notice)
            return True
        if header.msg_type == MessageType.QUERY_PLAN:
            self._last_plan = parse_query_plan(payload)
            return True
        if header.msg_type == MessageType.SBLR_COMPILED:
            self._last_sblr = parse_sblr_compiled(payload)
            return True
        return False

    @property
    def closed(self) -> bool:
        return self._closed

    @property
    def autocommit(self) -> bool:
        return self._autocommit

    @autocommit.setter
    def autocommit(self, value: bool) -> None:
        self._ensure_open()
        self._autocommit = bool(value)

    def cancel(self) -> None:
        self._ensure_open()
        payload = build_cancel_payload(0, 0)
        self._send_message(MessageType.CANCEL, payload, MSG_FLAG_URGENT)

    def _send_manager_frame(self, msg_type: int, payload: bytes) -> None:
        if not self._socket:
            raise errors.InterfaceError("no active socket")
        header = struct.pack(
            "<IHBBI",
            MANAGER_PROTOCOL_MAGIC,
            MANAGER_PROTOCOL_VERSION,
            msg_type,
            0,
            len(payload),
        )
        self._socket.sendall(header + payload)

    def _recv_manager_frame(self) -> tuple[int, bytes]:
        header = self._read_exact(MANAGER_HEADER_SIZE)
        magic, version, msg_type, _flags, payload_len = struct.unpack("<IHBBI", header)
        if magic != MANAGER_PROTOCOL_MAGIC:
            raise errors.OperationalError("manager frame magic mismatch")
        if version != MANAGER_PROTOCOL_VERSION:
            raise errors.OperationalError("manager frame version mismatch")
        if payload_len > MANAGER_MAX_PAYLOAD_SIZE:
            raise errors.OperationalError("manager payload too large")
        payload = self._read_exact(payload_len) if payload_len else b""
        return msg_type, payload

    @staticmethod
    def _pack_lpreface(text: str) -> bytes:
        encoded = text.encode("utf-8")
        return struct.pack("<I", len(encoded)) + encoded

    def _perform_manager_connect(self) -> None:
        if not self._config.manager_auth_token:
            raise errors.InterfaceError("manager_proxy mode requires manager_auth_token")

        manager_user = self._config.manager_username or self._config.user or "admin"
        manager_database = self._config.manager_database or self._config.database or ""
        manager_profile = self._config.manager_connection_profile or "native_v3"
        manager_intent = self._config.manager_client_intent or "native_v3"
        manager_flags = int(self._config.manager_client_flags or 0) & 0xFFFF
        auth_fast_path = self._config.manager_auth_fast_path is not False

        hello_payload = struct.pack("<HH", MCP_PROTOCOL_VERSION, manager_flags)
        self._send_manager_frame(MCP_MSG_HELLO, hello_payload)
        msg_type, _ = self._recv_manager_frame()
        if msg_type != MCP_MSG_STATUS_RESPONSE:
            raise errors.OperationalError("expected MCP hello status response")

        auth_start = bytearray()
        auth_start += self._pack_lpreface(manager_user)
        auth_start += struct.pack("<B", MCP_AUTH_METHOD_TOKEN)
        if auth_fast_path:
            token = self._config.manager_auth_token.encode("utf-8")
            auth_start += struct.pack("<I", len(token)) + token
        else:
            auth_start += struct.pack("<I", 0)

        self._send_manager_frame(MCP_MSG_AUTH_START, bytes(auth_start))
        msg_type, payload = self._recv_manager_frame()
        if msg_type == MCP_MSG_AUTH_CHALLENGE:
            token = self._config.manager_auth_token.encode("utf-8")
            self._send_manager_frame(MCP_MSG_AUTH_CONTINUE, struct.pack("<I", len(token)) + token)
            msg_type, payload = self._recv_manager_frame()

        if msg_type != MCP_MSG_AUTH_RESPONSE:
            raise errors.OperationalError("expected MCP auth response")
        if len(payload) < 1 + 4 + 256:
            raise errors.OperationalError("truncated MCP auth response")
        if payload[0] != 0:
            err_text = payload[5 : 5 + 256].split(b"\x00", 1)[0].decode("utf-8", errors="replace")
            raise errors.OperationalError(err_text or "MCP authentication failed")

        nonce = os.urandom(16)
        db_connect = bytearray(b"MCP1")
        db_connect += self._pack_lpreface(manager_database)
        db_connect += self._pack_lpreface(manager_profile)
        db_connect += self._pack_lpreface(manager_intent)
        db_connect += struct.pack("<H", len(nonce))
        db_connect += nonce

        self._send_manager_frame(MCP_MSG_DB_CONNECT, bytes(db_connect))
        msg_type, payload = self._recv_manager_frame()
        if msg_type != MCP_MSG_CONNECT_RESPONSE:
            raise errors.OperationalError("expected MCP connect response")
        if len(payload) < 1 + 2 + 2 + 16 + 64 + 32:
            raise errors.OperationalError("truncated MCP connect response")
        if payload[0] != 0:
            err_text = "MCP database connect failed"
            err_offset = 1 + 2 + 2 + 16 + 64 + 32
            if len(payload) >= err_offset + 4:
                err_len = struct.unpack_from("<I", payload, err_offset)[0]
                start = err_offset + 4
                end = start + err_len
                if len(payload) >= end:
                    err_text = payload[start:end].decode("utf-8", errors="replace")
            raise errors.OperationalError(err_text)

    def _startup_and_auth(self) -> None:
        self._authed = False
        self._parameters.clear()
        try:
            params = self._build_startup_params()
        except ValueError as exc:
            raise errors.InterfaceError(str(exc)) from exc
        features = 0
        if self._config.compression.lower() == "zstd":
            features |= FEATURE_COMPRESSION
        if self._config.binary_transfer:
            features |= FEATURE_STREAMING
        payload = build_startup_payload(features, params)
        self._send_message(MessageType.STARTUP, payload, force_zero=True)

        scram: Optional[ScramExchange] = None

        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.NEGOTIATE_VERSION:
                continue
            if header.msg_type == MessageType.AUTH_REQUEST:
                method, _ = parse_auth_request(payload)
                if method == AuthMethod.OK:
                    continue
                if method == AuthMethod.PASSWORD:
                    password_bytes = (self._config.password or "").encode("utf-8")
                    self._send_message(MessageType.AUTH_RESPONSE, password_bytes, force_zero=True)
                    continue
                if method == AuthMethod.SCRAM_SHA_256:
                    if scram is None:
                        scram = ScramExchange(self._config.user or "")
                    client_first = scram.client_first_message().encode("utf-8")
                    self._send_message(MessageType.AUTH_RESPONSE, client_first, force_zero=True)
                    continue
                raise errors.OperationalError("unsupported auth method")
            if header.msg_type == MessageType.AUTH_CONTINUE:
                method, _, data = parse_auth_continue(payload)
                if method != AuthMethod.SCRAM_SHA_256:
                    raise errors.OperationalError("unsupported auth continuation")
                if scram is None:
                    raise errors.OperationalError("SCRAM state missing")
                server_first = data.decode("utf-8", errors="replace")
                client_final = scram.handle_server_first(self._config.password or "", server_first)
                self._send_message(
                    MessageType.AUTH_RESPONSE,
                    client_final.encode("utf-8"),
                    force_zero=True,
                )
                continue
            if header.msg_type == MessageType.AUTH_OK:
                _, info = parse_auth_ok(payload)
                self._attachment_id = header.attachment_id
                self._txn_id = header.txn_id
                self._authed = True
                if scram and info.startswith(b"v="):
                    scram.verify_server_final(info.decode("utf-8", errors="replace"))
                continue
            if header.msg_type == MessageType.PARAMETER_STATUS:
                name, value = parse_parameter_status(payload)
                self._parameters[name] = value
                continue
            if header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                return
            if header.msg_type == MessageType.ERROR:
                self._raise_protocol_error(payload)
            continue

    def _build_startup_params(self) -> Dict[str, str]:
        params = {
            "database": self._config.database or "",
            "user": self._config.user or "",
        }
        if self._config.role:
            params["role"] = self._config.role
        if self._config.application_name:
            params["application_name"] = self._config.application_name
        selection = AuthPluginSelection(
            method_id=self._config.auth_method_id or "",
            payload_json=self._config.auth_payload_json or "",
            payload_b64=self._config.auth_payload_b64 or "",
            provider_profile=self._config.auth_provider_profile or "",
        )
        apply_auth_plugin_selection(params, selection)
        return params

    def _send_message(self, msg_type: int, payload: bytes, flags: int = 0, force_zero: bool = False) -> None:
        if not self._socket:
            raise errors.InterfaceError("no active socket")
        attachment = self._attachment_id if self._authed and not force_zero else b"\x00" * 16
        txn_id = self._txn_id if self._authed and not force_zero else 0
        header = MessageHeader(
            msg_type=msg_type,
            flags=flags,
            length=len(payload),
            sequence=self._sequence,
            attachment_id=attachment,
            txn_id=txn_id,
        )
        self._sequence = (self._sequence + 1) & 0xFFFFFFFF
        data = encode_message(header, payload)
        self._socket.sendall(data)

    def _recv_message(self):
        header_bytes = self._read_exact(HEADER_SIZE)
        header = decode_header(header_bytes)
        payload = self._read_exact(header.length) if header.length else b""
        return header, payload

    def _read_exact(self, n: int) -> bytes:
        buf = bytearray()
        while len(buf) < n:
            chunk = self._socket.recv(n - len(buf))
            if not chunk:
                raise errors.OperationalError("connection closed")
            buf.extend(chunk)
        return bytes(buf)

    def _execute_command(self, sql: str) -> None:
        span = self._begin_operation("execute_command", sql)
        self._send_simple_query(sql)
        try:
            self._drain_until_ready()
            self._end_operation(span, True)
        except Exception:
            self._end_operation(span, False)
            raise

    def _apply_schema(self) -> None:
        schema = (self._config.schema or "").strip()
        if not schema or schema.lower() == "public":
            return
        statement = _build_schema_statement(schema)
        if statement:
            self._execute_command(statement)

    def _send_simple_query(self, sql: str, max_rows: int = 0) -> None:
        flags = QUERY_FLAG_BINARY_RESULT if self._config.binary_transfer else 0
        payload = build_query_payload(sql, flags, max_rows, 0)
        self._send_message(MessageType.QUERY, payload)

    def _send_extended_query(self, sql: str, params, max_rows: int = 0) -> None:
        param_values = []
        param_types = []
        for param in params:
            value, oid = encode_param(param)
            param_values.append(value)
            param_types.append(oid)
        parse_payload = build_parse_payload("", sql, param_types)
        self._send_message(MessageType.PARSE, parse_payload)
        param_count = self._describe_statement("")
        if param_count >= 0 and param_count != len(param_types):
            raise errors.ProgrammingError("parameter count mismatch (07001)")
        result_formats = [FORMAT_BINARY] if self._config.binary_transfer else []
        bind_payload = build_bind_payload("", "", param_values, result_formats)
        self._send_message(MessageType.BIND, bind_payload)
        exec_payload = build_execute_payload("", max_rows)
        self._send_message(MessageType.EXECUTE, exec_payload)
        if max_rows == 0:
            self._send_message(MessageType.SYNC, b"")

    def _execute_query(self, sql: str, params=None, max_rows: int = 0):
        try:
            normalized_sql, ordered = normalize_query(sql, params)
        except ValueError as exc:
            raise errors.ProgrammingError(str(exc)) from exc
        span = self._begin_operation("execute_query", normalized_sql)
        try:
            if ordered:
                self._send_extended_query(normalized_sql, ordered, max_rows)
            else:
                self._send_simple_query(normalized_sql, max_rows)
            self._end_operation(span, True)
        except Exception:
            self._end_operation(span, False)
            raise
        return ResultStream(self, max_rows)

    def _describe_statement(self, statement_name: str) -> int:
        describe_payload = build_describe_payload(ord("S"), statement_name)
        self._send_message(MessageType.DESCRIBE, describe_payload)
        self._send_message(MessageType.SYNC, b"")
        param_count = -1
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.PARAMETER_DESCRIPTION:
                param_count = len(parse_parameter_description(payload))
            elif header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                return param_count

    def _drain_until_ready(self) -> None:
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                return

    def _raise_protocol_error(self, payload: bytes) -> None:
        try:
            _, sqlstate, message, detail, hint = parse_error_message(payload)
        except ValueError:
            raise errors.DatabaseError("query failed") from None
        parts = []
        if message:
            parts.append(message)
        if detail:
            parts.append(f"DETAIL: {detail}")
        if hint:
            parts.append(f"HINT: {hint}")
        text = "\n".join(parts) if parts else "query failed"
        if sqlstate:
            text = f"[{sqlstate}] {text}"
            raise _map_sqlstate(sqlstate)(text)
        raise errors.DatabaseError(text)

    def copy_in(self, sql: str, data: bytes, format: int = COPY_FORMAT_TEXT) -> int:
        """Execute a COPY FROM operation, sending data to the server.
        
        Args:
            sql: The COPY SQL statement (e.g., "COPY table FROM STDIN")
            data: The data to copy in bytes
            format: COPY_FORMAT_TEXT or COPY_FORMAT_BINARY
            
        Returns:
            Number of rows copied
        """
        self._ensure_open()
        span = self._begin_operation("copy_in", sql)
        
        # Send COPY SQL as a query
        try:
            self._send_simple_query(sql)
        except Exception:
            self._end_operation(span, False)
            raise
        
        # Wait for CopyInResponse
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._end_operation(span, False)
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.COPY_IN_RESPONSE:
                response = parse_copy_in_response(payload)
                # Use response.window_bytes if needed for flow control
                _ = response
                break
            if header.msg_type == MessageType.READY:
                self._end_operation(span, False)
                raise errors.OperationalError("expected COPY IN response")
        
        # Send data in chunks
        offset = 0
        chunk_size = 65536  # 64KB chunks
        while offset < len(data):
            chunk = data[offset:offset + chunk_size]
            payload = build_copy_data_payload(chunk)
            self._send_message(MessageType.COPY_DATA, payload)
            offset += len(chunk)
        
        # Send CopyDone
        self._send_message(MessageType.COPY_DONE, build_copy_done_payload())
        
        # Wait for CommandComplete
        rows_copied = 0
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._end_operation(span, False)
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.COMMAND_COMPLETE:
                _, rows_copied, _, _ = parse_command_complete(payload)
                break
            if header.msg_type == MessageType.READY:
                self._end_operation(span, False)
                raise errors.OperationalError("expected CommandComplete after COPY")
        
        # Wait for Ready
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                self._end_operation(span, True)
                return int(rows_copied)

    def copy_out(self, sql: str, format: int = COPY_FORMAT_TEXT) -> bytes:
        """Execute a COPY TO operation, receiving data from the server.
        
        Args:
            sql: The COPY SQL statement (e.g., "COPY table TO STDOUT")
            format: COPY_FORMAT_TEXT or COPY_FORMAT_BINARY
            
        Returns:
            The copied data as bytes
        """
        self._ensure_open()
        span = self._begin_operation("copy_out", sql)
        
        # Send COPY SQL as a query
        try:
            self._send_simple_query(sql)
        except Exception:
            self._end_operation(span, False)
            raise
        
        # Wait for CopyOutResponse
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._end_operation(span, False)
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.COPY_OUT_RESPONSE:
                response = parse_copy_out_response(payload)
                _ = response
                break
            if header.msg_type == MessageType.READY:
                self._end_operation(span, False)
                raise errors.OperationalError("expected COPY OUT response")
        
        # Collect data until CopyDone
        chunks = []
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._end_operation(span, False)
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.COPY_DATA:
                chunks.append(payload)
            elif header.msg_type == MessageType.COPY_DONE:
                break
            elif header.msg_type == MessageType.COPY_FAIL:
                self._end_operation(span, False)
                raise errors.OperationalError("COPY failed on server side")
            elif header.msg_type == MessageType.READY:
                self._end_operation(span, False)
                raise errors.OperationalError("unexpected READY during COPY")
        
        # Wait for CommandComplete
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._end_operation(span, False)
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.COMMAND_COMPLETE:
                _ = parse_command_complete(payload)
                break
            if header.msg_type == MessageType.READY:
                raise errors.OperationalError("expected CommandComplete after COPY")
        
        # Wait for Ready
        while True:
            header, payload = self._recv_message()
            if self._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                self._end_operation(span, True)
                return b"".join(chunks)


def _build_schema_statement(schema: str) -> str:
    trimmed = schema.strip()
    if not trimmed:
        return ""
    if "," in trimmed:
        parts = [part.strip() for part in trimmed.split(",") if part.strip()]
        if not parts:
            return ""
        quoted = ", ".join(_quote_identifier(part) for part in parts)
        return f"SET SEARCH_PATH TO {quoted}"
    return f"SET SCHEMA {_quote_identifier(trimmed)}"


def _quote_identifier(name: str) -> str:
    return '"' + name.replace('"', '""') + '"'


def _map_sqlstate(sqlstate: str):
    if len(sqlstate) == 5:
        full_map = {
            "01000": errors.Warning,
            "02000": errors.DatabaseError,
            "08001": errors.OperationalError,
            "08003": errors.OperationalError,
            "08004": errors.OperationalError,
            "08006": errors.OperationalError,
            "08P01": errors.OperationalError,
            "0A000": errors.NotSupportedError,
            "22001": errors.DataError,
            "22003": errors.DataError,
            "22007": errors.DataError,
            "22012": errors.DataError,
            "22023": errors.DataError,
            "22P02": errors.DataError,
            "22P03": errors.DataError,
            "23000": errors.IntegrityError,
            "23502": errors.IntegrityError,
            "23503": errors.IntegrityError,
            "23505": errors.IntegrityError,
            "23514": errors.IntegrityError,
            "28000": errors.OperationalError,
            "28P01": errors.OperationalError,
            "40001": errors.DatabaseError,
            "40P01": errors.DatabaseError,
            "42501": errors.ProgrammingError,
            "42601": errors.ProgrammingError,
            "42703": errors.ProgrammingError,
            "42704": errors.ProgrammingError,
            "42710": errors.ProgrammingError,
            "42883": errors.ProgrammingError,
            "42P01": errors.ProgrammingError,
            "42P07": errors.ProgrammingError,
            "53P00": errors.OperationalError,
            "53100": errors.OperationalError,
            "53200": errors.OperationalError,
            "53300": errors.OperationalError,
            "54000": errors.OperationalError,
            "57014": errors.OperationalError,
            "57P01": errors.OperationalError,
            "57P03": errors.OperationalError,
            "58000": errors.InternalError,
            "XX000": errors.InternalError,
        }
        mapped = full_map.get(sqlstate)
        if mapped:
            return mapped
    return errors.DatabaseError


QUERY_FLAG_BINARY_RESULT = 0x04


class ResultStream:
    def __init__(self, connection: Connection, page_size: int = 0):
        self._connection = connection
        self._page_size = page_size
        self.columns = []
        self.rowcount = -1
        self.lastrowid = None
        self._done = False

    def read_row(self):
        if self._done:
            return None
        while True:
            header, payload = self._connection._recv_message()
            if self._connection._handle_async(header, payload):
                continue
            if header.msg_type == MessageType.ERROR:
                self._connection._raise_protocol_error(payload)
            if header.msg_type == MessageType.ROW_DESCRIPTION:
                self.columns = parse_row_description(payload)
            elif header.msg_type == MessageType.DATA_ROW:
                values = parse_data_row(payload, len(self.columns))
                decoded = []
                for idx, value in enumerate(values):
                    if idx < len(self.columns):
                        col = self.columns[idx]
                        decoded.append(decode_value(col.type_oid, value.data, col.format))
                    else:
                        decoded.append(decode_value(0, value.data, FORMAT_BINARY))
                return tuple(decoded)
            elif header.msg_type == MessageType.COMMAND_COMPLETE:
                _, rows_affected, last_id, _ = parse_command_complete(payload)
                self.rowcount = int(rows_affected)
                self.lastrowid = int(last_id)
            elif header.msg_type == MessageType.PORTAL_SUSPENDED:
                exec_payload = build_execute_payload("", self._page_size)
                self._connection._send_message(MessageType.EXECUTE, exec_payload)
            elif header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._connection._txn_id = txn_id
                self._done = True
                return None


def _parse_uuid_bytes(value: str) -> Optional[bytes]:
    hex_value = value.replace("-", "").strip()
    if len(hex_value) != 32:
        return None
    try:
        return bytes.fromhex(hex_value)
    except ValueError:
        return None


def _parse_uint64(value: str) -> Optional[int]:
    try:
        return int(value.strip())
    except (ValueError, TypeError):
        return None
