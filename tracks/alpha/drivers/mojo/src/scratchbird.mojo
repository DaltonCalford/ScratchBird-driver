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
import datetime
from collections import Dict
from scratchbird.circuit_breaker import CircuitBreaker, CircuitBreakerError
from scratchbird.keepalive import KeepaliveTracker, KeepaliveConfig
from scratchbird.leak_detector import LeakDetector
from scratchbird.telemetry import TelemetryCollector

OID_BOOL = 16
OID_BYTEA = 17
OID_CHAR = 18
OID_INT8 = 20
OID_INT2 = 21
OID_INT4 = 23
OID_TEXT = 25
OID_JSON = 114
OID_XML = 142
OID_POINT = 600
OID_LSEG = 601
OID_PATH = 602
OID_BOX = 603
OID_POLYGON = 604
OID_LINE = 628
OID_FLOAT4 = 700
OID_FLOAT8 = 701
OID_CIRCLE = 718
OID_MONEY = 790
OID_MACADDR = 829
OID_CIDR = 650
OID_INET = 869
OID_MACADDR8 = 774
OID_BPCHAR = 1042
OID_VARCHAR = 1043
OID_DATE = 1082
OID_TIME = 1083
OID_TIMESTAMP = 1114
OID_TIMESTAMPTZ = 1184
OID_INTERVAL = 1186
OID_TIMETZ = 1266
OID_NUMERIC = 1700
OID_UUID = 2950
OID_JSONB = 3802
OID_RECORD = 2249
OID_INT4RANGE = 3904
OID_NUMRANGE = 3906
OID_TSRANGE = 3908
OID_TSTZRANGE = 3910
OID_DATERANGE = 3912
OID_INT8RANGE = 3926
OID_TSVECTOR = 3614
OID_TSQUERY = 3615
OID_SB_VECTOR = 16386

BASE_DATE = datetime.datetime(2000, 1, 1, 0, 0, 0)

class ScratchBirdJsonb:
    def __init__(self, raw: bytes, value=None):
        self.raw = raw
        self.value = value

class ScratchBirdJson:
    def __init__(self, raw: bytes, value=None):
        self.raw = raw
        self.value = value

class ScratchBirdGeometry:
    def __init__(self, wkb: bytes, srid=None, wkt: str = ""):
        self.wkb = wkb
        self.srid = srid
        self.wkt = wkt

class ScratchBirdRange:
    def __init__(self, lower=None, upper=None, lower_inclusive=False, upper_inclusive=False,
                 lower_infinite=False, upper_infinite=False, empty=False):
        self.lower = lower
        self.upper = upper
        self.lower_inclusive = lower_inclusive
        self.upper_inclusive = upper_inclusive
        self.lower_infinite = lower_infinite
        self.upper_infinite = upper_infinite
        self.empty = empty

class ScratchBirdInterval:
    def __init__(self, micros: int, days: int = 0, months: int = 0):
        self.micros = micros
        self.days = days
        self.months = months

class ScratchBirdDate:
    def __init__(self, value):
        self.value = value

class ScratchBirdTime:
    def __init__(self, value):
        self.value = value

class ScratchBirdTimestamp:
    def __init__(self, value):
        self.value = value

class ScratchBirdTimestampTZ:
    def __init__(self, value):
        self.value = value

class ScratchBirdDecimal:
    def __init__(self, value: str):
        self.value = value

class ScratchBirdMoney:
    def __init__(self, cents: int):
        self.cents = cents

class ScratchBirdRaw:
    def __init__(self, oid: int, data: bytes):
        self.oid = oid
        self.data = data

class ScratchBirdComposite:
    def __init__(self, raw: bytes, type_oid: int = OID_RECORD):
        self.raw = raw
        self.type_oid = type_oid


class ScratchBirdError(Exception):
    def __init__(self, message: str, sqlstate: str = "", detail: str = "", hint: str = ""):
        super().__init__(message)
        self.sqlstate = sqlstate
        self.detail = detail
        self.hint = hint

def _decode_int16(data: bytes) -> int:
    return struct.unpack_from("<h", data, 0)[0]

def _decode_int32(data: bytes) -> int:
    return struct.unpack_from("<i", data, 0)[0]

def _decode_int64(data: bytes) -> int:
    return struct.unpack_from("<q", data, 0)[0]

def _decode_float32(data: bytes) -> float:
    return struct.unpack_from("<f", data, 0)[0]

def _decode_float64(data: bytes) -> float:
    return struct.unpack_from("<d", data, 0)[0]

def _decode_uuid(data: bytes) -> str:
    if len(data) != 16:
        return data.hex()
    hex_str = data.hex()
    return f"{hex_str[0:8]}-{hex_str[8:12]}-{hex_str[12:16]}-{hex_str[16:20]}-{hex_str[20:32]}"

def _encode_length_prefixed(data: bytes) -> bytes:
    return struct.pack("<I", len(data)) + data

def _strip_length_prefix(data: bytes) -> bytes:
    if len(data) < 4:
        return data
    length = struct.unpack_from("<I", data, 0)[0]
    if length <= len(data) - 4:
        return data[4 : 4 + length]
    return data

def _decode_date(data: bytes):
    if len(data) < 4:
        return ScratchBirdDate(None)
    days = _decode_int32(data)
    value = (BASE_DATE + datetime.timedelta(days=days)).date()
    return ScratchBirdDate(value)

def _decode_time(data: bytes):
    if len(data) < 8:
        return ScratchBirdTime(None)
    micros = _decode_int64(data)
    seconds, micros = divmod(micros, 1000000)
    hours, rem = divmod(seconds, 3600)
    minutes, seconds = divmod(rem, 60)
    value = datetime.time(int(hours % 24), int(minutes), int(seconds), int(micros))
    return ScratchBirdTime(value)

def _decode_timestamp(data: bytes):
    if len(data) < 8:
        return ScratchBirdTimestamp(None)
    micros = _decode_int64(data)
    value = BASE_DATE + datetime.timedelta(microseconds=micros)
    return ScratchBirdTimestamp(value)

def _decode_timestamptz(data: bytes):
    if len(data) < 8:
        return ScratchBirdTimestampTZ(None)
    micros = _decode_int64(data)
    value = BASE_DATE + datetime.timedelta(microseconds=micros)
    return ScratchBirdTimestampTZ(value)

def _decode_interval(data: bytes):
    if len(data) < 16:
        return ScratchBirdInterval(0, 0, 0)
    micros = _decode_int64(data[0:8])
    days = _decode_int32(data[8:12])
    months = _decode_int32(data[12:16])
    return ScratchBirdInterval(micros, days, months)

def _looks_like_array(text: str) -> bool:
    stripped = text.strip()
    return stripped.startswith("{") and stripped.endswith("}")

def _split_array_items(text: str):
    items = []
    depth = 0
    buf = ""
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == '{':
            depth += 1
            buf += ch
        elif ch == '}':
            depth = max(0, depth - 1)
            buf += ch
        elif ch == ',' and depth == 0:
            items.append(buf)
            buf = ""
        else:
            buf += ch
        i += 1
    if buf:
        items.append(buf)
    return items

def _parse_array_literal(text: str):
    trimmed = text.strip()
    if trimmed == "" or trimmed == "{}":
        return []
    if trimmed.startswith("{") and trimmed.endswith("}"):
        trimmed = trimmed[1:-1]
    items = _split_array_items(trimmed)
    out = []
    for item in items:
        item = item.strip()
        if item == "NULL":
            out.append(None)
        elif _looks_like_array(item):
            out.append(_parse_array_literal(item))
        else:
            out.append(item)
    return out

def _parse_vector_literal(text: str):
    trimmed = text.strip()
    if trimmed.startswith("[") and trimmed.endswith("]"):
        trimmed = trimmed[1:-1]
    if trimmed.strip() == "":
        return []
    out = []
    for part in trimmed.split(','):
        val = part.strip()
        if val == "":
            continue
        try:
            out.append(float(val))
        except Exception:
            pass
    return out

def _parse_range_literal(text: str):
    trimmed = text.strip()
    if trimmed == "empty":
        return ScratchBirdRange(empty=True)
    if len(trimmed) < 2:
        return ScratchBirdRange()
    lower_inc = trimmed.startswith("[")
    upper_inc = trimmed.endswith("]")
    inner = trimmed[1:-1]
    if "," in inner:
        lower_text, upper_text = inner.split(",", 1)
    else:
        lower_text, upper_text = inner, ""
    lower_text = lower_text.strip()
    upper_text = upper_text.strip()
    lower_inf = lower_text == ""
    upper_inf = upper_text == ""
    lower = None if lower_inf else lower_text
    upper = None if upper_inf else upper_text
    return ScratchBirdRange(lower, upper, lower_inc, upper_inc, lower_inf, upper_inf, False)

def decode_value(type_oid: int, data: bytes):
    if data is None:
        return None
    if type_oid == OID_BOOL:
        return len(data) > 0 and data[0] == 1
    if type_oid == OID_INT2:
        return _decode_int16(data)
    if type_oid == OID_INT4:
        return _decode_int32(data)
    if type_oid == OID_INT8:
        return _decode_int64(data)
    if type_oid == OID_FLOAT4:
        return _decode_float32(data)
    if type_oid == OID_FLOAT8:
        return _decode_float64(data)
    if type_oid == OID_NUMERIC:
        raw = _strip_length_prefix(data)
        return ScratchBirdDecimal(raw.decode("utf-8", errors="replace"))
    if type_oid == OID_MONEY:
        return ScratchBirdMoney(_decode_int64(data))
    if type_oid in (OID_TEXT, OID_VARCHAR, OID_CHAR, OID_BPCHAR, OID_JSON, OID_XML,
                    OID_TSVECTOR, OID_TSQUERY, OID_INET, OID_CIDR, OID_MACADDR, OID_MACADDR8,
                    OID_RECORD, OID_INT4RANGE, OID_INT8RANGE, OID_NUMRANGE, OID_TSRANGE,
                    OID_TSTZRANGE, OID_DATERANGE):
        raw = _strip_length_prefix(data)
        text = raw.decode("utf-8", errors="replace")
        if type_oid in (OID_INT4RANGE, OID_INT8RANGE, OID_NUMRANGE, OID_TSRANGE, OID_TSTZRANGE, OID_DATERANGE):
            return _parse_range_literal(text)
        if _looks_like_array(text):
            return _parse_array_literal(text)
        return text
    if type_oid == OID_JSONB:
        return ScratchBirdJsonb(_strip_length_prefix(data))
    if type_oid == OID_BYTEA:
        return _strip_length_prefix(data)
    if type_oid == OID_DATE:
        return _decode_date(data)
    if type_oid == OID_TIME:
        return _decode_time(data)
    if type_oid == OID_TIMESTAMP:
        return _decode_timestamp(data)
    if type_oid == OID_TIMESTAMPTZ:
        return _decode_timestamptz(data)
    if type_oid == OID_INTERVAL:
        return _decode_interval(data)
    if type_oid == OID_UUID:
        return _decode_uuid(data)
    if type_oid == OID_SB_VECTOR:
        raw = _strip_length_prefix(data)
        text = raw.decode("utf-8", errors="replace")
        return _parse_vector_literal(text)
    if type_oid in (OID_POINT, OID_LSEG, OID_PATH, OID_BOX, OID_POLYGON, OID_LINE, OID_CIRCLE):
        return ScratchBirdGeometry(_strip_length_prefix(data))
    return ScratchBirdRaw(type_oid, data)

def _format_array_item(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, list):
        return _format_array_literal(value)
    return str(value)

def _format_array_literal(values: list) -> str:
    items = []
    for value in values:
        items.append(_format_array_item(value))
    return "{" + ",".join(items) + "}"

def encode_value(value):
    if value is None:
        return 0, b""
    if isinstance(value, ScratchBirdRaw):
        return value.oid, value.data
    if isinstance(value, ScratchBirdJsonb):
        return OID_JSONB, _encode_length_prefixed(value.raw)
    if isinstance(value, ScratchBirdJson):
        return OID_JSON, _encode_length_prefixed(value.raw)
    if isinstance(value, ScratchBirdGeometry):
        return OID_POINT, _encode_length_prefixed(value.wkb)
    if isinstance(value, ScratchBirdRange):
        lower = "" if value.lower is None else str(value.lower)
        upper = "" if value.upper is None else str(value.upper)
        prefix = "[" if value.lower_inclusive else "("
        suffix = "]" if value.upper_inclusive else ")"
        literal = f"{prefix}{lower},{upper}{suffix}"
        return OID_NUMRANGE, _encode_length_prefixed(literal.encode("utf-8"))
    if isinstance(value, ScratchBirdInterval):
        out = bytearray(16)
        struct.pack_into("<q", out, 0, value.micros)
        struct.pack_into("<i", out, 8, value.days)
        struct.pack_into("<i", out, 12, value.months)
        return OID_INTERVAL, bytes(out)
    if isinstance(value, ScratchBirdDate):
        if value.value is None:
            return OID_DATE, b""
        days = (datetime.datetime.combine(value.value, datetime.time.min) - BASE_DATE).days
        return OID_DATE, struct.pack("<i", days)
    if isinstance(value, ScratchBirdTime):
        if value.value is None:
            return OID_TIME, b""
        micros = (value.value.hour * 3600 + value.value.minute * 60 + value.value.second) * 1000000 + value.value.microsecond
        return OID_TIME, struct.pack("<q", micros)
    if isinstance(value, ScratchBirdTimestamp):
        if value.value is None:
            return OID_TIMESTAMP, b""
        delta = value.value - BASE_DATE
        micros = int(delta.total_seconds() * 1000000)
        return OID_TIMESTAMP, struct.pack("<q", micros)
    if isinstance(value, ScratchBirdTimestampTZ):
        if value.value is None:
            return OID_TIMESTAMPTZ, b""
        delta = value.value - BASE_DATE
        micros = int(delta.total_seconds() * 1000000)
        return OID_TIMESTAMPTZ, struct.pack("<q", micros)
    if isinstance(value, ScratchBirdDecimal):
        return OID_NUMERIC, _encode_length_prefixed(value.value.encode("utf-8"))
    if isinstance(value, ScratchBirdMoney):
        return OID_MONEY, struct.pack("<q", value.cents)
    if isinstance(value, str):
        return OID_TEXT, _encode_length_prefixed(value.encode("utf-8"))
    if isinstance(value, bytes):
        return OID_BYTEA, _encode_length_prefixed(value)
    if isinstance(value, bool):
        return OID_BOOL, b"\x01" if value else b"\x00"
    if isinstance(value, int):
        return OID_INT8, struct.pack("<q", value)
    if isinstance(value, float):
        return OID_FLOAT8, struct.pack("<d", value)
    if isinstance(value, list):
        if len(value) > 0 and all(isinstance(item, (int, float)) for item in value):
            literal = "[" + ", ".join([str(item) for item in value]) + "]"
            return OID_SB_VECTOR, _encode_length_prefixed(literal.encode("utf-8"))
        literal = _format_array_literal(value)
        return 0, _encode_length_prefixed(literal.encode("utf-8"))
    return OID_TEXT, _encode_length_prefixed(str(value).encode("utf-8"))

PROTOCOL_MAGIC = b"SBWP"
PROTOCOL_MAJOR = 1
PROTOCOL_MINOR = 1
HEADER_SIZE = 40

class MessageType:
    STARTUP = 0x01
    AUTH_RESPONSE = 0x02
    QUERY = 0x03
    PARSE = 0x04
    BIND = 0x05
    DESCRIBE = 0x06
    EXECUTE = 0x07
    CLOSE = 0x08
    SYNC = 0x09
    FLUSH = 0x0A
    CANCEL = 0x0B
    TERMINATE = 0x0C
    TXN_BEGIN = 0x15
    TXN_COMMIT = 0x16
    TXN_ROLLBACK = 0x17
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
    PARAMETER_DESCRIPTION = 0x50
    PARSE_COMPLETE = 0x4A
    BIND_COMPLETE = 0x4B
    CLOSE_COMPLETE = 0x4C
    NO_DATA = 0x4E
    PORTAL_SUSPENDED = 0x4D
    PONG = 0x5D

MSG_FLAG_URGENT = 0x08

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

class AuthMethod:
    OK = 0
    PASSWORD = 1
    SCRAM_SHA256 = 3

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

class ScratchBirdConfig:
    def __init__(self, dsn: str = ""):
        self.dsn = dsn or ""
        self.host = "localhost"
        self.port = 3092
        self.protocol = "native"
        self.front_door_mode = "direct"
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
        self.manager_auth_token = ""
        self.manager_username = ""
        self.manager_database = ""
        self.manager_connection_profile = "native_v3"
        self.manager_client_intent = "native_v3"
        self.manager_client_flags = 0
        self.manager_auth_fast_path = True

        if self.dsn:
            self._apply_params(parse_dsn(self.dsn))

    def _apply_params(self, params):
        params = {str(k).lower(): v for k, v in params.items()}

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
        if "protocol" in params:
            self.protocol = normalize_native_protocol(params["protocol"])
        elif "parser" in params:
            self.protocol = normalize_native_protocol(params["parser"])
        elif "dialect" in params:
            self.protocol = normalize_native_protocol(params["dialect"])
        if "front_door_mode" in params:
            self.front_door_mode = normalize_front_door_mode(params["front_door_mode"])
        elif "frontdoormode" in params:
            self.front_door_mode = normalize_front_door_mode(params["frontdoormode"])
        elif "connection_mode" in params:
            self.front_door_mode = normalize_front_door_mode(params["connection_mode"])
        elif "ingress_mode" in params:
            self.front_door_mode = normalize_front_door_mode(params["ingress_mode"])
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
        if "manager_auth_token" in params:
            self.manager_auth_token = params["manager_auth_token"]
        elif "mcp_auth_token" in params:
            self.manager_auth_token = params["mcp_auth_token"]
        if "manager_username" in params:
            self.manager_username = params["manager_username"]
        elif "mcp_username" in params:
            self.manager_username = params["mcp_username"]
        if "manager_database" in params:
            self.manager_database = params["manager_database"]
        elif "mcp_database" in params:
            self.manager_database = params["mcp_database"]
        if "manager_connection_profile" in params:
            self.manager_connection_profile = params["manager_connection_profile"]
        elif "mcp_connection_profile" in params:
            self.manager_connection_profile = params["mcp_connection_profile"]
        if "manager_client_intent" in params:
            self.manager_client_intent = params["manager_client_intent"]
        elif "mcp_client_intent" in params:
            self.manager_client_intent = params["mcp_client_intent"]
        if "manager_client_flags" in params:
            try:
                self.manager_client_flags = int(params["manager_client_flags"])
            except Exception:
                pass
        elif "mcp_client_flags" in params:
            try:
                self.manager_client_flags = int(params["mcp_client_flags"])
            except Exception:
                pass
        if "manager_auth_fast_path" in params:
            self.manager_auth_fast_path = _as_bool(params["manager_auth_fast_path"])
        elif "mcp_auth_fast_path" in params:
            self.manager_auth_fast_path = _as_bool(params["mcp_auth_fast_path"])

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
        if self.front_door_mode:
            params["front_door_mode"] = self.front_door_mode
        if self.manager_auth_token:
            params["manager_auth_token"] = self.manager_auth_token
        if self.manager_username:
            params["manager_username"] = self.manager_username
        if self.manager_database:
            params["manager_database"] = self.manager_database
        if self.manager_connection_profile:
            params["manager_connection_profile"] = self.manager_connection_profile
        if self.manager_client_intent:
            params["manager_client_intent"] = self.manager_client_intent
        if self.manager_client_flags:
            params["manager_client_flags"] = str(self.manager_client_flags)
        if self.manager_auth_fast_path is not None:
            params["manager_auth_fast_path"] = "true" if self.manager_auth_fast_path else "false"

        query = urllib.parse.urlencode(params) if params else ""
        host = self.host or "localhost"
        port = self.port or 3092
        path = "/" + self.database if self.database else ""
        dsn = f"scratchbird://{userinfo}{host}:{port}{path}"
        if query:
            dsn = dsn + "?" + query
        return dsn


def normalize_native_protocol(value) -> str:
    normalized = str(value or "").strip().lower()
    if normalized in ("", "native", "scratchbird", "scratchbird-native", "scratchbird_native"):
        return "native"
    raise RuntimeError("Only protocol=native is supported; connect to the native parser listener/port.")


def normalize_front_door_mode(value) -> str:
    normalized = str(value or "").strip().lower()
    if normalized in ("", "direct"):
        return "direct"
    if normalized in ("manager_proxy", "manager-proxy", "managed"):
        return "manager_proxy"
    raise RuntimeError("front_door_mode must be direct or manager_proxy.")


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


class ScratchBirdStream:
    def __init__(self, connection, sql: str, params=None, fetch_size: int = 1):
        self._connection = connection
        self._columns = []
        self._buffer = []
        self._done = False
        self._fetch_size = fetch_size if fetch_size > 0 else 1

        if params is None:
            params = []
        self._result = connection._extended_query(sql, params, self._fetch_size)
        self._columns = self._result.columns
        self._buffer = list(self._result.rows)

    def __iter__(self):
        return self

    def __next__(self):
        if self._buffer:
            return self._buffer.pop(0)
        if self._done:
            raise StopIteration
        self._result = self._connection._fetch_more(self._fetch_size, self._columns)
        self._buffer = list(self._result.rows)
        self._columns = self._result.columns
        if not self._buffer:
            self._done = True
            raise StopIteration
        return self._buffer.pop(0)

    def close(self):
        self._done = True


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


def build_parse_payload(statement_name: str, query: str, param_types) -> bytes:
    name_bytes = statement_name.encode("utf-8")
    query_bytes = query.encode("utf-8")
    param_types = param_types if param_types is not None else []
    out = bytearray()
    out += struct.pack("<I", len(name_bytes))
    out += name_bytes
    out += struct.pack("<I", len(query_bytes))
    out += query_bytes
    out += struct.pack("<H", len(param_types))
    out += struct.pack("<H", 0)
    for oid in param_types:
        out += struct.pack("<I", int(oid))
    return bytes(out)


def build_describe_payload(describe_type: int, name: str) -> bytes:
    name_bytes = name.encode("utf-8")
    out = bytearray()
    out += struct.pack("<B3x", describe_type)
    out += struct.pack("<I", len(name_bytes))
    out += name_bytes
    return bytes(out)


def build_bind_payload(portal_name: str, statement_name: str, params, result_formats) -> bytes:
    portal_bytes = portal_name.encode("utf-8")
    stmt_bytes = statement_name.encode("utf-8")
    params = params if params is not None else []
    result_formats = result_formats if result_formats is not None else []
    param_formats = []
    for param in params:
        param_formats.append(param["format"])

    out = bytearray()
    out += struct.pack("<I", len(portal_bytes))
    out += portal_bytes
    out += struct.pack("<I", len(stmt_bytes))
    out += stmt_bytes
    out += struct.pack("<H", len(param_formats))
    for fmt_code in param_formats:
        out += struct.pack("<H", int(fmt_code))
    out += struct.pack("<H", len(params))
    out += struct.pack("<H", 0)
    for param in params:
        if param["null"]:
            out += struct.pack("<I", 0xFFFFFFFF)
        else:
            data = param["data"]
            out += struct.pack("<I", len(data))
            out += data
    out += struct.pack("<H", len(result_formats))
    for fmt_code in result_formats:
        out += struct.pack("<H", int(fmt_code))
    return bytes(out)


def build_execute_payload(portal_name: str, max_rows: int) -> bytes:
    portal_bytes = portal_name.encode("utf-8")
    out = bytearray()
    out += struct.pack("<I", len(portal_bytes))
    out += portal_bytes
    out += struct.pack("<I", max_rows)
    return bytes(out)


def build_cancel_payload(cancel_type: int, target_seq: int) -> bytes:
    out = bytearray()
    out += struct.pack("<I", cancel_type)
    out += struct.pack("<I", target_seq)
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


def parse_parameter_description(payload: bytes):
    if len(payload) < 4:
        raise RuntimeError("parameter description truncated")
    count = struct.unpack_from("<H", payload, 0)[0]
    offset = 4
    types = []
    for _ in range(count):
        if offset + 4 > len(payload):
            raise RuntimeError("parameter description truncated")
        types.append(struct.unpack_from("<I", payload, offset)[0])
        offset += 4
    return types


def parse_error_message(payload: bytes):
    offset = 0
    severity = ""
    sqlstate = ""
    message = ""
    detail = ""
    hint = ""
    while offset < len(payload):
        field = payload[offset]
        offset += 1
        if field == 0:
            break
        start = offset
        while offset < len(payload) and payload[offset] != 0:
            offset += 1
        if offset >= len(payload):
            break
        value = payload[start:offset].decode("utf-8", errors="replace")
        offset += 1
        if field == ord("S"):
            severity = value
        elif field == ord("C"):
            sqlstate = value
        elif field == ord("M"):
            message = value
        elif field == ord("D"):
            detail = value
        elif field == ord("H"):
            hint = value
    return severity, sqlstate, message, detail, hint


def parse_command_complete(payload: bytes):
    if len(payload) < 20:
        raise RuntimeError("command complete truncated")
    command_type = payload[0]
    rows = struct.unpack_from("<Q", payload, 4)[0]
    last_id = struct.unpack_from("<Q", payload, 12)[0]
    tag_bytes = payload[20:]
    tag = tag_bytes.decode("utf-8", errors="replace")
    null_idx = tag.find("\\x00")
    if null_idx >= 0:
        tag = tag[:null_idx]
    return command_type, rows, last_id, tag


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
        self._connection_id = "conn-" + secrets.token_hex(4)
        self._circuit_breaker = CircuitBreaker()
        self._telemetry = TelemetryCollector()
        self._keepalive_tracker = KeepaliveTracker(KeepaliveConfig())
        self._leak_detector = LeakDetector()
        self._leak_detector.start()
        self._leak_guard = self._leak_detector.checkout(self._connection_id, Dict[String, String]())
        self._connect()

    def _connect(self):
        self.config.protocol = normalize_native_protocol(self.config.protocol)
        self.config.front_door_mode = normalize_front_door_mode(self.config.front_door_mode)
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
        if self.config.front_door_mode == "manager_proxy":
            self._perform_manager_connect()
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

    def _append_length_prefixed_string(self, value: str) -> bytes:
        encoded = value.encode("utf-8")
        return struct.pack("<I", len(encoded)) + encoded

    def _send_manager_frame(self, msg_type: int, payload: bytes):
        header = struct.pack(
            "<I H B B I",
            MANAGER_PROTOCOL_MAGIC,
            MANAGER_PROTOCOL_VERSION,
            msg_type,
            0,
            len(payload),
        )
        self._socket.sendall(header + payload)

    def _recv_manager_frame(self):
        header = self._read_exact(MANAGER_HEADER_SIZE)
        magic, version, msg_type, _, length = struct.unpack("<I H B B I", header)
        if magic != MANAGER_PROTOCOL_MAGIC:
            raise RuntimeError("Manager frame magic mismatch")
        if version != MANAGER_PROTOCOL_VERSION:
            raise RuntimeError("Manager frame version mismatch")
        if length > MANAGER_MAX_PAYLOAD_SIZE:
            raise RuntimeError("Manager payload too large")
        payload = self._read_exact(length) if length > 0 else b""
        return msg_type, payload

    def _perform_manager_connect(self):
        token = self.config.manager_auth_token or ""
        if not token:
            raise RuntimeError("manager_proxy mode requires manager_auth_token")
        manager_user = self.config.manager_username or self.config.user or "admin"
        manager_database = self.config.manager_database or self.config.database or ""
        manager_profile = self.config.manager_connection_profile or "native_v3"
        manager_intent = self.config.manager_client_intent or "native_v3"
        manager_flags = int(self.config.manager_client_flags or 0) & 0xFFFF
        auth_fast_path = self.config.manager_auth_fast_path is not False

        hello = struct.pack("<H H", MCP_PROTOCOL_VERSION, manager_flags)
        self._send_manager_frame(MCP_MSG_HELLO, hello)
        msg_type, payload = self._recv_manager_frame()
        if msg_type != MCP_MSG_STATUS_RESPONSE:
            raise RuntimeError("expected MCP hello status response")

        auth_start = bytearray()
        auth_start.extend(self._append_length_prefixed_string(manager_user))
        auth_start.append(MCP_AUTH_METHOD_TOKEN)
        if auth_fast_path:
            token_bytes = token.encode("utf-8")
            auth_start.extend(struct.pack("<I", len(token_bytes)))
            auth_start.extend(token_bytes)
        else:
            auth_start.extend(struct.pack("<I", 0))
        self._send_manager_frame(MCP_MSG_AUTH_START, bytes(auth_start))
        msg_type, payload = self._recv_manager_frame()
        if msg_type == MCP_MSG_AUTH_CHALLENGE:
            token_bytes = token.encode("utf-8")
            auth_continue = struct.pack("<I", len(token_bytes)) + token_bytes
            self._send_manager_frame(MCP_MSG_AUTH_CONTINUE, auth_continue)
            msg_type, payload = self._recv_manager_frame()
        if msg_type != MCP_MSG_AUTH_RESPONSE:
            raise RuntimeError("expected MCP auth response")
        if len(payload) < 1 + 4 + 256:
            raise RuntimeError("truncated MCP auth response")
        if payload[0] != 0:
            err = payload[5:261].decode("utf-8", errors="replace").rstrip("\x00")
            raise RuntimeError(err if err else "MCP authentication failed")

        nonce = secrets.token_bytes(16)
        db_connect = bytearray()
        db_connect.extend(b"MCP1")
        db_connect.extend(self._append_length_prefixed_string(manager_database))
        db_connect.extend(self._append_length_prefixed_string(manager_profile))
        db_connect.extend(self._append_length_prefixed_string(manager_intent))
        db_connect.extend(struct.pack("<H", len(nonce)))
        db_connect.extend(nonce)
        self._send_manager_frame(MCP_MSG_DB_CONNECT, bytes(db_connect))
        msg_type, payload = self._recv_manager_frame()
        if msg_type != MCP_MSG_CONNECT_RESPONSE:
            raise RuntimeError("expected MCP connect response")
        if len(payload) < 1 + 2 + 2 + 16 + 64 + 32:
            raise RuntimeError("truncated MCP connect response")
        if payload[0] != 0:
            err = "MCP database connect failed"
            err_offset = 1 + 2 + 2 + 16 + 64 + 32
            if len(payload) >= err_offset + 4:
                err_len = struct.unpack_from("<I", payload, err_offset)[0]
                if len(payload) >= err_offset + 4 + err_len:
                    err = payload[err_offset + 4 : err_offset + 4 + err_len].decode("utf-8", errors="replace")
            raise RuntimeError(err)

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
        if self._leak_guard:
            self._leak_guard.release()
        self._leak_detector.stop()

    def _begin_operation(self, name: String, sql: String) -> Optional[SpanContext]:
        if not self._circuit_breaker.allow_request():
            raise RuntimeError("Circuit breaker is OPEN")
        if self._keepalive_tracker.needs_validation():
            self.ping()
            self._keepalive_tracker.mark_active()
        var span = self._telemetry.start_span(name)
        if span:
            span.value().with_attribute("db.statement", sql)
        return span

    def _end_operation(self, span: Optional[SpanContext], success: Bool):
        if success:
            self._circuit_breaker.record_success()
        else:
            self._circuit_breaker.record_failure()
        self._keepalive_tracker.mark_active()
        self._telemetry.end_span(span, success)

    def query(self, sql: str, params=None) -> ScratchBirdResult:
        var span = self._begin_operation("query", sql)
        try:
            if params is not None:
                var result = self._extended_query(sql, params)
                self._end_operation(span, True)
                return result
            payload = build_query_payload(sql, 0, 0, 0)
            self._send_message(MessageType.QUERY, payload)
            var result = self._read_resultset()
            self._end_operation(span, True)
            return result
        except Exception as e:
            self._end_operation(span, False)
            raise e

    def stream(self, sql: str, params=None, fetch_size: int = 1) -> ScratchBirdStream:
        return ScratchBirdStream(self, sql, params, fetch_size)

    def _extended_query(self, sql: str, params, max_rows: int = 0) -> ScratchBirdResult:
        if params is None:
            params = []
        param_values = []
        param_types = []
        for value in params:
            oid, data = encode_value(value)
            param_values.append({"format": 1, "data": data, "null": value is None})
            param_types.append(oid)

        parse_payload = build_parse_payload("", sql, param_types)
        self._send_message(MessageType.PARSE, parse_payload)
        describe_payload = build_describe_payload(ord("S"), "")
        self._send_message(MessageType.DESCRIBE, describe_payload)
        self._send_message(MessageType.SYNC, b"")

        param_count = -1
        while True:
            msg_type, payload = self._recv_message()
            if msg_type == MessageType.PARAMETER_DESCRIPTION:
                param_count = len(parse_parameter_description(payload))
            elif msg_type == MessageType.ERROR:
                self._raise_error(payload)
            elif msg_type == MessageType.READY:
                break
            else:
                continue

        if param_count >= 0 and param_count != len(params):
            raise ScratchBirdError("parameter count mismatch", "07001")

        result_formats = [1] if self.config.binary_transfer else []
        bind_payload = build_bind_payload("", "", param_values, result_formats)
        self._send_message(MessageType.BIND, bind_payload)
        exec_payload = build_execute_payload("", max_rows)
        self._send_message(MessageType.EXECUTE, exec_payload)
        self._send_message(MessageType.SYNC, b"")
        return self._read_resultset(max_rows > 0, [])

    def _fetch_more(self, max_rows: int, existing_columns) -> ScratchBirdResult:
        exec_payload = build_execute_payload("", max_rows)
        self._send_message(MessageType.EXECUTE, exec_payload)
        self._send_message(MessageType.SYNC, b"")
        return self._read_resultset(max_rows > 0, existing_columns)

    def _read_resultset(self, streaming: bool = False, existing_columns=None) -> ScratchBirdResult:
        columns = existing_columns if existing_columns is not None else []
        rows = []
        rowcount = 0
        while True:
            msg_type, payload = self._recv_message()
            if msg_type == MessageType.ROW_DESCRIPTION:
                cols = parse_row_description(payload)
                columns = [ScratchBirdColumn(name, oid, fmt) for name, oid, fmt in cols]
            elif msg_type == MessageType.DATA_ROW:
                values = parse_data_row(payload, len(columns))
                decoded = []
                for idx in range(len(values)):
                    value = values[idx]
                    if idx < len(columns) and value is not None:
                        decoded.append(decode_value(columns[idx].type_oid, value))
                    else:
                        decoded.append(value)
                rows.append(decoded)
            elif msg_type == MessageType.COMMAND_COMPLETE:
                try:
                    _, rows_affected, _, _ = parse_command_complete(payload)
                    rowcount = rows_affected
                except Exception:
                    rowcount = len(rows)
            elif msg_type == MessageType.NO_DATA:
                rowcount = len(rows)
            elif msg_type == MessageType.PORTAL_SUSPENDED:
                if streaming:
                    return ScratchBirdResult(rows, columns, rowcount)
            elif msg_type == MessageType.READY:
                return ScratchBirdResult(rows, columns, rowcount)
            elif msg_type == MessageType.ERROR:
                self._raise_error(payload)
            else:
                continue

    def _raise_error(self, payload: bytes):
        _, sqlstate, message, detail, hint = parse_error_message(payload)
        text = message if message else "query error"
        raise ScratchBirdError(text, sqlstate, detail, hint)

    def prepare(self, sql: str) -> ScratchBirdStatement:
        return ScratchBirdStatement(self, sql)

    def begin(self, **kwargs):
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

        payload = build_txn_begin_payload(
            int(flags),
            int(kwargs.get("conflict_action", 0)),
            int(kwargs.get("autocommit_mode", 0)),
            int(kwargs.get("isolation_level", ISOLATION_READ_COMMITTED)),
            int(kwargs.get("access_mode", 0)),
            int(deferrable),
            int(wait_mode),
            int(kwargs.get("timeout_ms", 0)),
        )
        self._send_message(MessageType.TXN_BEGIN, payload)
        self._drain_until_ready()

    def commit(self):
        if self._txn_id == 0:
            return
        payload = build_txn_commit_payload(0)
        self._send_message(MessageType.TXN_COMMIT, payload)
        self._drain_until_ready()

    def rollback(self):
        if self._txn_id == 0:
            return
        payload = build_txn_rollback_payload(0)
        self._send_message(MessageType.TXN_ROLLBACK, payload)
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

    def cancel(self):
        payload = build_cancel_payload(0, 0)
        self._send_message(MessageType.CANCEL, payload, flags=MSG_FLAG_URGENT)

    def _drain_until_ready(self):
        while True:
            msg_type, payload = self._recv_message()
            if msg_type == MessageType.READY:
                return
            if msg_type == MessageType.ERROR:
                self._raise_error(payload)


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
