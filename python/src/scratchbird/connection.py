"""Connection implementation for ScratchBird Python driver (SBWP v1.1)."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional

import socket
import ssl

from . import errors
from .dsn import parse_dsn
from .cursor import Cursor
from .protocol import (
    AuthMethod,
    MessageType,
    MSG_FLAG_URGENT,
    FEATURE_COMPRESSION,
    FEATURE_STREAMING,
    HEADER_SIZE,
    MessageHeader,
    build_bind_payload,
    build_cancel_payload,
    build_execute_payload,
    build_parse_payload,
    build_query_payload,
    build_startup_payload,
    decode_header,
    encode_message,
    parse_auth_continue,
    parse_auth_ok,
    parse_auth_request,
    parse_command_complete,
    parse_data_row,
    parse_error_message,
    parse_parameter_status,
    parse_ready,
    parse_row_description,
)
from .scram import ScramExchange
from .sql import normalize_query
from .types import FORMAT_BINARY, decode_value, encode_param


@dataclass
class ConnectionConfig:
    host: str = "localhost"
    port: int = 3092
    database: Optional[str] = None
    user: Optional[str] = None
    password: Optional[str] = None
    schema: Optional[str] = None
    sslmode: str = "require"
    sslrootcert: Optional[str] = None
    sslcert: Optional[str] = None
    sslkey: Optional[str] = None
    connect_timeout: int = 30
    socket_timeout: int = 0
    application_name: Optional[str] = None
    binary_transfer: bool = True
    compression: str = "off"
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
    cfg.database = params.get("database", cfg.database)
    cfg.user = params.get("user", cfg.user)
    cfg.password = params.get("password", cfg.password)
    cfg.schema = params.get("schema", params.get("search_path", params.get("searchpath", params.get("currentschema", cfg.schema))))
    cfg.sslmode = params.get("sslmode", params.get("ssl", cfg.sslmode))
    cfg.sslrootcert = params.get("sslrootcert", cfg.sslrootcert)
    cfg.sslcert = params.get("sslcert", cfg.sslcert)
    cfg.sslkey = params.get("sslkey", cfg.sslkey)
    cfg.connect_timeout = int(params.get("connect_timeout", cfg.connect_timeout))
    cfg.socket_timeout = int(params.get("socket_timeout", cfg.socket_timeout))
    cfg.application_name = params.get("application_name", cfg.application_name)
    cfg.binary_transfer = bool(params.get("binary_transfer", cfg.binary_transfer))
    cfg.compression = params.get("compression", cfg.compression) or "off"
    cfg.extra = {
        k: v
        for k, v in params.items()
        if k not in {
            "host",
            "port",
            "database",
            "user",
            "password",
            "schema",
            "search_path",
            "searchpath",
            "currentschema",
            "sslmode",
            "ssl",
            "sslrootcert",
            "sslcert",
            "sslkey",
            "connect_timeout",
            "socket_timeout",
            "application_name",
            "binary_transfer",
            "compression",
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
        self._connect()

    def _connect(self) -> None:
        if not self._config.user or not self._config.database:
            raise errors.InterfaceError("user and database are required")
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
            ctx.verify_mode = ssl.CERT_REQUIRED
            ctx.check_hostname = sslmode == "verify-full"
        else:
            ctx.verify_mode = ssl.CERT_NONE
            ctx.check_hostname = False
        if self._config.sslrootcert:
            ctx.load_verify_locations(self._config.sslrootcert)
        if self._config.sslcert and self._config.sslkey:
            ctx.load_cert_chain(self._config.sslcert, self._config.sslkey)

        try:
            sock = ctx.wrap_socket(raw_sock, server_hostname=self._config.host)
        except ssl.SSLError:
            raw_sock.close()
            raise
        self._socket = sock

        self._startup_and_auth()
        self._apply_schema()
        self._connected = True

    def close(self) -> None:
        if not self._closed:
            self._closed = True
            self._connected = False
            if self._socket:
                try:
                    self._socket.close()
                except OSError:
                    pass

    def commit(self) -> None:
        self._ensure_open()
        self._execute_command("COMMIT")

    def rollback(self) -> None:
        self._ensure_open()
        self._execute_command("ROLLBACK")

    def cursor(self) -> Cursor:
        self._ensure_open()
        cur = Cursor(self)
        self._cursors.append(cur)
        return cur

    def execute(self, sql: str, params=None) -> Cursor:
        cur = self.cursor()
        cur.execute(sql, params)
        return cur

    def executemany(self, sql: str, seq_of_params) -> Cursor:
        cur = self.cursor()
        cur.executemany(sql, seq_of_params)
        return cur

    def setinputsizes(self, sizes) -> None:
        self._ensure_open()

    def setoutputsize(self, size, column=None) -> None:
        self._ensure_open()

    def _ensure_open(self) -> None:
        if self._closed:
            raise errors.InterfaceError("connection is closed")

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

    def _startup_and_auth(self) -> None:
        self._authed = False
        self._parameters.clear()
        params = {
            "database": self._config.database or "",
            "user": self._config.user or "",
        }
        if self._config.application_name:
            params["application_name"] = self._config.application_name
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
        self._send_simple_query(sql)
        self._drain_until_ready()

    def _apply_schema(self) -> None:
        schema = (self._config.schema or "").strip()
        if not schema or schema.lower() == "public":
            return
        statement = _build_schema_statement(schema)
        if statement:
            self._execute_command(statement)

    def _send_simple_query(self, sql: str) -> None:
        flags = QUERY_FLAG_BINARY_RESULT if self._config.binary_transfer else 0
        payload = build_query_payload(sql, flags, 0, 0)
        self._send_message(MessageType.QUERY, payload)

    def _send_extended_query(self, sql: str, params) -> None:
        param_values = []
        param_types = []
        for param in params:
            value, oid = encode_param(param)
            param_values.append(value)
            param_types.append(oid)
        parse_payload = build_parse_payload("", sql, param_types)
        self._send_message(MessageType.PARSE, parse_payload)
        result_formats = [FORMAT_BINARY] if self._config.binary_transfer else []
        bind_payload = build_bind_payload("", "", param_values, result_formats)
        self._send_message(MessageType.BIND, bind_payload)
        exec_payload = build_execute_payload("", 0)
        self._send_message(MessageType.EXECUTE, exec_payload)
        self._send_message(MessageType.SYNC, b"")

    def _execute_query(self, sql: str, params=None):
        normalized_sql, ordered = normalize_query(sql, params)
        if ordered:
            self._send_extended_query(normalized_sql, ordered)
        else:
            self._send_simple_query(normalized_sql)

        columns = []
        rows = []
        rowcount = -1
        while True:
            header, payload = self._recv_message()
            if header.msg_type == MessageType.ERROR:
                self._raise_protocol_error(payload)
            if header.msg_type == MessageType.ROW_DESCRIPTION:
                columns = parse_row_description(payload)
            elif header.msg_type == MessageType.DATA_ROW:
                values = parse_data_row(payload, len(columns))
                decoded = []
                for idx, value in enumerate(values):
                    if idx < len(columns):
                        col = columns[idx]
                        decoded.append(decode_value(col.type_oid, value.data, col.format))
                    else:
                        decoded.append(decode_value(0, value.data, FORMAT_BINARY))
                rows.append(tuple(decoded))
            elif header.msg_type == MessageType.COMMAND_COMPLETE:
                _, rows_affected, _, _ = parse_command_complete(payload)
                rowcount = int(rows_affected)
            elif header.msg_type == MessageType.PARAMETER_STATUS:
                name, value = parse_parameter_status(payload)
                self._parameters[name] = value
            elif header.msg_type == MessageType.READY:
                _, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                break
        if rowcount < 0:
            rowcount = len(rows)
        return columns, rows, rowcount

    def _drain_until_ready(self) -> None:
        while True:
            header, payload = self._recv_message()
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
    prefix = sqlstate[:2]
    return {
        "01": errors.Warning,
        "02": errors.DatabaseError,
        "08": errors.OperationalError,
        "0A": errors.NotSupportedError,
        "22": errors.DataError,
        "23": errors.IntegrityError,
        "28": errors.OperationalError,
        "40": errors.DatabaseError,
        "42": errors.ProgrammingError,
        "53": errors.OperationalError,
        "54": errors.OperationalError,
        "57": errors.OperationalError,
        "58": errors.InternalError,
        "XX": errors.InternalError,
    }.get(prefix, errors.DatabaseError)


QUERY_FLAG_BINARY_RESULT = 0x04
