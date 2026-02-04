# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import socket
import ssl
import struct
import base64
import hashlib
import hmac
import secrets
import urllib.parse

PROTOCOL_MAGIC = b"SBWP"
PROTOCOL_MAJOR = 1
PROTOCOL_MINOR = 1
HEADER_SIZE = 40

class MessageType:
    STARTUP = 0x01
    AUTH_RESPONSE = 0x02
    QUERY = 0x03
    PING = 0x1B
    SET_OPTION = 0x1C

    AUTH_REQUEST = 0x40
    AUTH_OK = 0x41
    AUTH_CONTINUE = 0x42
    READY = 0x43
    ROW_DESCRIPTION = 0x44
    DATA_ROW = 0x45
    COMMAND_COMPLETE = 0x46
    ERROR = 0x48
    PARAMETER_STATUS = 0x4F
    PONG = 0x5D

class AuthMethod:
    OK = 0
    PASSWORD = 1
    SCRAM_SHA256 = 3

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
            self._apply_params(parse_dsn(self.dsn))

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


def parse_dsn(dsn: str):
    parsed = urllib.parse.urlparse(dsn)
    params = dict(urllib.parse.parse_qsl(parsed.query))
    if parsed.hostname:
        params.setdefault("host", parsed.hostname)
    if parsed.port:
        params.setdefault("port", str(parsed.port))
    if parsed.path and parsed.path != "/":
        params.setdefault("database", parsed.path.lstrip("/"))
    if parsed.username:
        params.setdefault("user", parsed.username)
    if parsed.password:
        params.setdefault("password", parsed.password)
    return params


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


class ScramExchange:
    def __init__(self, username: str, digest: str = "sha256"):
        self.username = username
        self.digest = digest
        self.client_nonce = generate_nonce()
        self.client_first_bare = f"n={normalize_username(username)},r={self.client_nonce}"
        self.server_first = ""
        self.client_final = ""
        self.expected_server_signature = b""

    def client_first_message(self) -> str:
        return f"n,,{self.client_first_bare}"

    def handle_server_first(self, password: str, server_first: str) -> str:
        nonce, salt, iterations = parse_server_first(server_first)
        if not nonce.startswith(self.client_nonce):
            raise RuntimeError("scram nonce mismatch")

        salted_password = pbkdf2_hmac(password, salt, iterations, self.digest)
        client_key = hmac_digest(salted_password, "Client Key", self.digest)
        stored_key = hash_digest(client_key, self.digest)
        server_key = hmac_digest(salted_password, "Server Key", self.digest)

        client_final_without_proof = f"c=biws,r={nonce}"
        auth_message = f"{self.client_first_bare},{server_first},{client_final_without_proof}"

        client_signature = hmac_digest(stored_key, auth_message, self.digest)
        client_proof = bytes(a ^ b for a, b in zip(client_key, client_signature))
        proof_b64 = base64.b64encode(client_proof).decode("ascii")

        self.server_first = server_first
        self.client_final = f"{client_final_without_proof},p={proof_b64}"
        self.expected_server_signature = hmac_digest(server_key, auth_message, self.digest)
        return self.client_final

    def verify_server_final(self, server_final: str) -> None:
        signature = parse_server_final(server_final)
        if signature != self.expected_server_signature:
            raise RuntimeError("scram server signature mismatch")


def generate_nonce(length: int = 24) -> str:
    return secrets.token_urlsafe(length)[:length]


def normalize_username(username: str) -> str:
    return username.replace("=", "=3D").replace(",", "=2C")


def parse_server_first(message: str):
    if not message.startswith("r="):
        raise RuntimeError("invalid server-first")
    parts = dict(part.split("=", 1) for part in message.split(",") if "=" in part)
    nonce = parts.get("r")
    salt_b64 = parts.get("s")
    iterations = parts.get("i")
    if nonce is None or salt_b64 is None or iterations is None:
        raise RuntimeError("invalid server-first")
    salt = base64.b64decode(salt_b64.encode("ascii"))
    return nonce, salt, int(iterations)


def parse_server_final(message: str) -> bytes:
    if not message.startswith("v="):
        raise RuntimeError("invalid server-final")
    return base64.b64decode(message[2:].encode("ascii"))


def pbkdf2_hmac(password: str, salt: bytes, iterations: int, digest: str) -> bytes:
    return hashlib.pbkdf2_hmac(digest, password.encode("utf-8"), salt, iterations)


def hmac_digest(key: bytes, msg: str, digest: str) -> bytes:
    return hmac.new(key, msg.encode("utf-8"), digest).digest()


def hash_digest(data: bytes, digest: str) -> bytes:
    return hashlib.new(digest, data).digest()


def build_param_list(params: dict) -> bytes:
    parts = bytearray()
    for key, value in params.items():
        parts += key.encode("utf-8") + b"\x00"
        parts += value.encode("utf-8") + b"\x00"
    parts += b"\x00"
    return bytes(parts)


def build_startup_payload(features: int, params: dict) -> bytes:
    param_bytes = build_param_list(params)
    out = bytearray()
    out += struct.pack("<B", PROTOCOL_MAJOR)
    out += struct.pack("<B", PROTOCOL_MINOR)
    out += struct.pack("<H", 0)
    out += struct.pack("<Q", features)
    out += param_bytes
    return bytes(out)


def build_query_payload(sql: str, flags: int, max_rows: int, timeout_ms: int) -> bytes:
    sql_bytes = sql.encode("utf-8") + b"\x00"
    out = bytearray()
    out += struct.pack("<I", flags)
    out += struct.pack("<I", max_rows)
    out += struct.pack("<I", timeout_ms)
    out += sql_bytes
    return bytes(out)


def build_set_option_payload(name: str, value: str) -> bytes:
    name_bytes = name.encode("utf-8")
    value_bytes = value.encode("utf-8")
    out = bytearray()
    out += struct.pack("<I", len(name_bytes)) + name_bytes
    out += struct.pack("<I", len(value_bytes)) + value_bytes
    return bytes(out)


def build_txn_begin_payload(flags: int, conflict_action: int, autocommit_mode: int, isolation_level: int,
                            access_mode: int, deferrable: int, wait_mode: int, timeout_ms: int) -> bytes:
    return struct.pack("<HBBBBBBI", flags, conflict_action, autocommit_mode, isolation_level,
                       access_mode, deferrable, wait_mode, timeout_ms)


def build_txn_commit_payload(flags: int) -> bytes:
    return struct.pack("<B3x", flags)


def build_txn_rollback_payload(flags: int) -> bytes:
    return struct.pack("<B3x", flags)


def encode_message(msg_type: int, flags: int, sequence: int, attachment_id: bytes, txn_id: int, payload: bytes) -> bytes:
    out = bytearray(HEADER_SIZE + len(payload))
    out[0:4] = PROTOCOL_MAGIC
    out[4] = PROTOCOL_MAJOR
    out[5] = PROTOCOL_MINOR
    out[6] = msg_type
    out[7] = flags
    struct.pack_into("<I", out, 8, len(payload))
    struct.pack_into("<I", out, 12, sequence)
    out[16:32] = attachment_id
    struct.pack_into("<Q", out, 32, txn_id)
    out[HEADER_SIZE:] = payload
    return bytes(out)


def decode_header(data: bytes):
    if len(data) != HEADER_SIZE:
        raise RuntimeError("invalid header length")
    if data[0:4] != PROTOCOL_MAGIC:
        raise RuntimeError("invalid protocol magic")
    major = data[4]
    minor = data[5]
    if major != PROTOCOL_MAJOR or minor != PROTOCOL_MINOR:
        raise RuntimeError("unsupported protocol version")
    msg_type = data[6]
    flags = data[7]
    length = struct.unpack_from("<I", data, 8)[0]
    sequence = struct.unpack_from("<I", data, 12)[0]
    attachment_id = data[16:32]
    txn_id = struct.unpack_from("<Q", data, 32)[0]
    return msg_type, flags, length, sequence, attachment_id, txn_id


def parse_auth_request(payload: bytes):
    if len(payload) < 4:
        raise RuntimeError("auth request truncated")
    method = payload[0]
    return method, payload[4:]


def parse_auth_continue(payload: bytes):
    if len(payload) < 8:
        raise RuntimeError("auth continue truncated")
    method = payload[0]
    stage = payload[1]
    data_len = struct.unpack_from("<I", payload, 4)[0]
    if 8 + data_len > len(payload):
        raise RuntimeError("auth continue truncated")
    return method, stage, payload[8 : 8 + data_len]


def parse_auth_ok(payload: bytes):
    if len(payload) < 20:
        raise RuntimeError("auth ok truncated")
    session_id = payload[0:16]
    info_len = struct.unpack_from("<I", payload, 16)[0]
    if 20 + info_len > len(payload):
        raise RuntimeError("auth ok truncated")
    return session_id, payload[20 : 20 + info_len]


def parse_ready(payload: bytes):
    if len(payload) < 20:
        raise RuntimeError("ready truncated")
    status = payload[0]
    txn_id = struct.unpack_from("<Q", payload, 4)[0]
    visibility = struct.unpack_from("<Q", payload, 12)[0]
    return status, txn_id, visibility


def parse_parameter_status(payload: bytes):
    if len(payload) < 8:
        raise RuntimeError("parameter status truncated")
    name_len = struct.unpack_from("<I", payload, 0)[0]
    name_start = 4
    name_end = name_start + name_len
    if name_end + 4 > len(payload):
        raise RuntimeError("parameter status truncated")
    value_len = struct.unpack_from("<I", payload, name_end)[0]
    value_start = name_end + 4
    value_end = value_start + value_len
    if value_end > len(payload):
        raise RuntimeError("parameter status truncated")
    name = payload[name_start:name_end].decode("utf-8", errors="replace")
    value = payload[value_start:value_end].decode("utf-8", errors="replace")
    return name, value


def parse_row_description(payload: bytes):
    if len(payload) < 4:
        raise RuntimeError("row description truncated")
    count = struct.unpack_from("<H", payload, 0)[0]
    offset = 4
    columns = []
    for _ in range(count):
        if offset + 4 > len(payload):
            raise RuntimeError("row description truncated")
        name_len = struct.unpack_from("<I", payload, offset)[0]
        offset += 4
        if offset + name_len > len(payload):
            raise RuntimeError("row description truncated")
        name = payload[offset : offset + name_len].decode("utf-8", errors="replace")
        offset += name_len
        if offset + 18 > len(payload):
            raise RuntimeError("row description truncated")
        table_oid = struct.unpack_from("<I", payload, offset)[0]
        offset += 4
        column_index = struct.unpack_from("<H", payload, offset)[0]
        offset += 2
        type_oid = struct.unpack_from("<I", payload, offset)[0]
        offset += 4
        type_size = struct.unpack_from("<h", payload, offset)[0]
        offset += 2
        type_modifier = struct.unpack_from("<i", payload, offset)[0]
        offset += 4
        fmt = payload[offset]
        offset += 1
        nullable = payload[offset] == 1
        offset += 1
        offset += 2
        columns.append((name, type_oid, fmt))
    return columns


def parse_data_row(payload: bytes, column_count: int):
    if len(payload) < 4:
        raise RuntimeError("row data truncated")
    count = struct.unpack_from("<H", payload, 0)[0]
    null_bytes = struct.unpack_from("<H", payload, 2)[0]
    if count != column_count:
        raise RuntimeError("row data column count mismatch")
    offset = 4
    if offset + null_bytes > len(payload):
        raise RuntimeError("row data truncated")
    null_bitmap = payload[offset : offset + null_bytes]
    offset += null_bytes
    values = []
    for idx in range(count):
        byte_index = idx // 8
        bit_index = idx % 8
        is_null = byte_index < len(null_bitmap) and (null_bitmap[byte_index] & (1 << bit_index))
        if is_null:
            values.append(None)
            continue
        if offset + 4 > len(payload):
            raise RuntimeError("row data truncated")
        length = struct.unpack_from("<i", payload, offset)[0]
        offset += 4
        if length < 0:
            values.append(None)
            continue
        if offset + length > len(payload):
            raise RuntimeError("row data truncated")
        data = payload[offset : offset + length]
        offset += length
        values.append(data)
    return values


class ScratchBirdConnection:
    def __init__(self, config: ScratchBirdConfig):
        self.config = config
        self._socket = None
        self._sequence = 0
        self._attachment_id = b"\x00" * 16
        self._txn_id = 0
        self._parameters = {}
        self._notification_handlers = []
        self._last_plan = None
        self._last_sblr = None
        self._connect()

    def _connect(self):
        if not self.config.user or not self.config.database:
            raise RuntimeError("user and database are required")
        if not self.config.binary_transfer:
            raise RuntimeError("binary_transfer=false is not supported")
        if (self.config.compression or "").lower() == "zstd":
            raise RuntimeError("compression=zstd is not supported")
        if (self.config.sslmode or "require").lower() == "disable":
            raise RuntimeError("TLS is required for ScratchBird connections")

        raw_sock = socket.create_connection(
            (self.config.host, self.config.port),
            timeout=self.config.connect_timeout_ms / 1000 if self.config.connect_timeout_ms else None,
        )
        raw_sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        raw_sock.settimeout(self.config.socket_timeout_ms / 1000 if self.config.socket_timeout_ms else None)

        ctx = ssl.create_default_context()
        ctx.minimum_version = ssl.TLSVersion.TLSv1_3
        ctx.maximum_version = ssl.TLSVersion.TLSv1_3
        sslmode = (self.config.sslmode or "require").lower()
        if sslmode in ("verify-ca", "verify-full"):
            ctx.check_hostname = sslmode == "verify-full"
            ctx.verify_mode = ssl.CERT_REQUIRED
        else:
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
        if self.config.sslrootcert:
            ctx.load_verify_locations(self.config.sslrootcert)
        if self.config.sslcert and self.config.sslkey:
            ctx.load_cert_chain(self.config.sslcert, self.config.sslkey, password=self.config.sslpassword or None)

        sock = ctx.wrap_socket(raw_sock, server_hostname=self.config.host)
        self._socket = sock
        self._startup_and_auth()

    def _startup_and_auth(self):
        params = {
            "user": self.config.user,
            "database": self.config.database,
            "application_name": self.config.application_name or "mojo",
            "binary_transfer": "true" if self.config.binary_transfer else "false",
        }
        if self.config.search_path:
            params["search_path"] = self.config.search_path
        if self.config.role:
            params["role"] = self.config.role
        if self.config.compression:
            params["compression"] = self.config.compression
        if self.config.fetch_size:
            params["fetch_size"] = str(self.config.fetch_size)

        payload = build_startup_payload(0, params)
        self._send_message(MessageType.STARTUP, payload, force_zero=True)

        scram = None
        while True:
            msg_type, payload = self._recv_message()
            if msg_type == MessageType.AUTH_REQUEST:
                method, _ = parse_auth_request(payload)
                if method == AuthMethod.OK:
                    continue
                if method == AuthMethod.PASSWORD:
                    password_bytes = (self.config.password or "").encode("utf-8")
                    self._send_message(MessageType.AUTH_RESPONSE, password_bytes, force_zero=True)
                    continue
                if method != AuthMethod.SCRAM_SHA256:
                    raise RuntimeError("unsupported auth method")
                if scram is None:
                    scram = ScramExchange(self.config.user)
                client_first = scram.client_first_message().encode("utf-8")
                self._send_message(MessageType.AUTH_RESPONSE, client_first, force_zero=True)
            elif msg_type == MessageType.AUTH_CONTINUE:
                method, stage, data = parse_auth_continue(payload)
                if method != AuthMethod.SCRAM_SHA256:
                    raise RuntimeError("unsupported auth method")
                if scram is None:
                    raise RuntimeError("SCRAM state missing")
                server_first = data.decode("utf-8")
                client_final = scram.handle_server_first(self.config.password or "", server_first)
                self._send_message(MessageType.AUTH_RESPONSE, client_final.encode("utf-8"), force_zero=True)
            elif msg_type == MessageType.AUTH_OK:
                self._attachment_id, info = parse_auth_ok(payload)
                if scram and info.startswith(b"v="):
                    scram.verify_server_final(info.decode("utf-8", errors="replace"))
            elif msg_type == MessageType.READY:
                status, txn_id, _ = parse_ready(payload)
                self._txn_id = txn_id
                return
            elif msg_type == MessageType.PARAMETER_STATUS:
                name, value = parse_parameter_status(payload)
                self._parameters[name] = value
            elif msg_type == MessageType.ERROR:
                raise RuntimeError("authentication failed")

    def _send_message(self, msg_type: int, payload: bytes, flags: int = 0, force_zero: bool = False):
        self._sequence += 1
        attachment = self._attachment_id if not force_zero else b"\x00" * 16
        txn_id = self._txn_id if not force_zero else 0
        msg = encode_message(msg_type, flags, self._sequence, attachment, txn_id, payload)
        self._socket.sendall(msg)

    def _recv_message(self):
        header = self._read_exact(HEADER_SIZE)
        msg_type, flags, length, sequence, attachment_id, txn_id = decode_header(header)
        if length > 0:
            payload = self._read_exact(length)
        else:
            payload = b""
        self._attachment_id = attachment_id
        self._txn_id = txn_id
        return msg_type, payload

    def _read_exact(self, length: int) -> bytes:
        out = bytearray()
        while len(out) < length:
            chunk = self._socket.recv(length - len(out))
            if not chunk:
                raise RuntimeError("socket closed")
            out.extend(chunk)
        return bytes(out)

    def close(self):
        if self._socket is not None:
            try:
                self._socket.close()
            except Exception:
                pass
            self._socket = None

    def query(self, sql: str, params=None) -> ScratchBirdResult:
        if params:
            raise RuntimeError("parameterized queries not yet supported in Mojo native client")
        payload = build_query_payload(sql, 0, 0, 0)
        self._send_message(MessageType.QUERY, payload)
        columns = []
        rows = []
        rowcount = 0
        while True:
            msg_type, payload = self._recv_message()
            if msg_type == MessageType.ROW_DESCRIPTION:
                cols = parse_row_description(payload)
                columns = [ScratchBirdColumn(name, oid, fmt) for name, oid, fmt in cols]
            elif msg_type == MessageType.DATA_ROW:
                values = parse_data_row(payload, len(columns))
                rows.append(values)
            elif msg_type == MessageType.COMMAND_COMPLETE:
                rowcount = len(rows)
            elif msg_type == MessageType.READY:
                return ScratchBirdResult(rows, columns, rowcount)
            elif msg_type == MessageType.ERROR:
                raise RuntimeError("query error")

    def prepare(self, sql: str) -> ScratchBirdStatement:
        return ScratchBirdStatement(self, sql)

    def begin(self, **kwargs):
        flags = 0
        payload = build_txn_begin_payload(flags, 0, 0, 0, 0, 0, 0, 0)
        self._send_message(0x15, payload)
        self._drain_until_ready()

    def commit(self):
        payload = build_txn_commit_payload(0)
        self._send_message(0x16, payload)
        self._drain_until_ready()

    def rollback(self):
        payload = build_txn_rollback_payload(0)
        self._send_message(0x17, payload)
        self._drain_until_ready()

    def set_option(self, name: str, value: str):
        payload = build_set_option_payload(name, value)
        self._send_message(MessageType.SET_OPTION, payload)
        self._drain_until_ready()

    def ping(self):
        self._send_message(MessageType.PING, b"")
        while True:
            msg_type, payload = self._recv_message()
            if msg_type in (MessageType.PONG, MessageType.READY):
                return
            if msg_type == MessageType.ERROR:
                raise RuntimeError("ping failed")

    def _drain_until_ready(self):
        while True:
            msg_type, payload = self._recv_message()
            if msg_type == MessageType.READY:
                return
            if msg_type == MessageType.ERROR:
                raise RuntimeError("command failed")


def connect(config: ScratchBirdConfig) -> ScratchBirdConnection:
    conn = ScratchBirdConnection(config)
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
