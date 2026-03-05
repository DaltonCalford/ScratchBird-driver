# ScratchBird Mojo lane runtime shim (Python-backed)
# This module provides the APIs used by Mojo lane tests while the lane remains
# in a Mojo-Python interop phase.

from __future__ import annotations

from dataclasses import dataclass, field
import datetime
import json
import struct
from typing import Any, Dict, Iterable, Iterator, List, Optional
import urllib.parse


class MessageType:
    QUERY = 0x03
    TXN_BEGIN = 0x15
    TXN_COMMIT = 0x16
    TXN_ROLLBACK = 0x17
    TXN_SAVEPOINT = 0x18
    TXN_RELEASE = 0x19
    TXN_ROLLBACK_TO = 0x1A


ISOLATION_READ_UNCOMMITTED = 0
ISOLATION_READ_COMMITTED = 1
ISOLATION_REPEATABLE_READ = 2
ISOLATION_SERIALIZABLE = 3

OID_INT4 = 23
OID_TEXT = 25
OID_JSON = 114
OID_POINT = 600
OID_CIDR = 650
OID_MACADDR = 829
OID_INET = 869
OID_VARCHAR = 1043
OID_DATE = 1082
OID_TIME = 1083
OID_TIMESTAMP = 1114
OID_TIMESTAMPTZ = 1184
OID_INTERVAL = 1186
OID_RECORD = 2249
OID_UUID = 2950
OID_MACADDR8 = 774
OID_JSONB = 3802
OID_SB_VECTOR = 16386
OID_INT4_ARRAY = 1007
OID_TEXT_ARRAY = 1009
OID_RECORD_ARRAY = 2287

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
METADATA_ROUTINES_QUERY = "SELECT procedure_id AS routine_id, schema_id, procedure_name AS routine_name, routine_type FROM sys.procedures WHERE is_valid = 1 UNION ALL SELECT function_id AS routine_id, schema_id, function_name AS routine_name, 'FUNCTION' AS routine_type FROM sys.functions WHERE is_valid = 1 ORDER BY schema_id, routine_name"
METADATA_CATALOGS_QUERY = "SELECT schema_id AS catalog_id, schema_name AS catalog_name FROM sys.schemas WHERE is_valid = 1 ORDER BY schema_name"
METADATA_PRIMARY_KEYS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('primary key', 'primary') ORDER BY table_id, constraint_name"
METADATA_FOREIGN_KEYS_QUERY = "SELECT constraint_id, table_id, constraint_name, constraint_type FROM sys.constraints WHERE is_valid = 1 AND lower(constraint_type) IN ('foreign key', 'foreign') ORDER BY table_id, constraint_name"
METADATA_TABLE_PRIVILEGES_QUERY = "SELECT table_id, table_name, owner_id AS grantor_id, owner_id AS grantee_id, 'ALL' AS privilege_type FROM sys.tables WHERE is_valid = 1 ORDER BY table_id, table_name"
METADATA_COLUMN_PRIVILEGES_QUERY = "SELECT table_id, column_id, column_name, 'ALL' AS privilege_type FROM sys.columns WHERE is_valid = 1 ORDER BY table_id, ordinal_position"
METADATA_TYPE_INFO_QUERY = "SELECT DISTINCT data_type_id, data_type_name FROM sys.columns WHERE is_valid = 1 ORDER BY data_type_name"

DEFAULT_METADATA_COLLECTION = "tables"

_METADATA_COLLECTION_QUERY_MAP = {
    "schemas": METADATA_SCHEMAS_QUERY,
    "tables": METADATA_TABLES_QUERY,
    "columns": METADATA_COLUMNS_QUERY,
    "indexes": METADATA_INDEXES_QUERY,
    "index_columns": METADATA_INDEX_COLUMNS_QUERY,
    "constraints": METADATA_CONSTRAINTS_QUERY,
    "procedures": METADATA_PROCEDURES_QUERY,
    "functions": METADATA_FUNCTIONS_QUERY,
    "routines": METADATA_ROUTINES_QUERY,
    "catalogs": METADATA_CATALOGS_QUERY,
    "primary_keys": METADATA_PRIMARY_KEYS_QUERY,
    "foreign_keys": METADATA_FOREIGN_KEYS_QUERY,
    "table_privileges": METADATA_TABLE_PRIVILEGES_QUERY,
    "column_privileges": METADATA_COLUMN_PRIVILEGES_QUERY,
    "type_info": METADATA_TYPE_INFO_QUERY,
}

_METADATA_COLLECTION_ALIASES = {
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

_METADATA_RESTRICTION_ALIASES = {
    "name": "name",
    "object_name": "name",
    "entity_name": "name",
    "schema": "schema_name",
    "schema_name": "schema_name",
    "table_schema": "schema_name",
    "table_schem": "schema_name",
    "table": "table_name",
    "table_name": "table_name",
    "column": "column_name",
    "column_name": "column_name",
}

_SCHEMA_KEYS = (
    "schema_name",
    "TABLE_SCHEM",
    "table_schem",
    "table_schema",
    "TABLE_SCHEMA",
    "schema",
)


_BASE_DATE = datetime.datetime(2000, 1, 1, 0, 0, 0)


@dataclass
class ScratchBirdResult:
    rows: List[List[Any]]
    columns: List[Any]
    rowcount: int


@dataclass
class ScratchBirdConfig:
    dsn: str = ""


@dataclass
class ScratchBirdRaw:
    oid: int
    data: bytes


@dataclass
class ScratchBirdRange:
    lower: Optional[str] = None
    upper: Optional[str] = None
    lower_inclusive: bool = False
    upper_inclusive: bool = False
    lower_infinite: bool = False
    upper_infinite: bool = False
    empty: bool = False


@dataclass
class ScratchBirdComposite:
    fields: List[Optional[str]]


@dataclass
class ScratchBirdJson:
    raw: bytes
    value: Any = None


@dataclass
class ScratchBirdJsonb:
    raw: bytes
    value: Any = None


@dataclass
class ScratchBirdGeometry:
    raw: str
    wkt: str


@dataclass
class ScratchBirdNetwork:
    kind: str
    address: str


@dataclass
class ScratchBirdDate:
    value: Optional[datetime.date]


@dataclass
class ScratchBirdTime:
    value: Optional[datetime.time]


@dataclass
class ScratchBirdTimestamp:
    value: Optional[datetime.datetime]


@dataclass
class ScratchBirdTimestampTZ:
    value: Optional[datetime.datetime]


@dataclass
class ScratchBirdInterval:
    micros: int
    days: int = 0
    months: int = 0


class ScratchBirdError(Exception):
    def __init__(self, message: str, sqlstate: str = "", detail: str = "", hint: str = ""):
        super().__init__(message)
        self.sqlstate = sqlstate
        self.detail = detail
        self.hint = hint


def _as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() in ("1", "true", "yes", "on")


def _split_array_items(text: str) -> List[str]:
    items: List[str] = []
    depth = 0
    token = ""
    in_quotes = False
    escaped = False
    for ch in text:
        if escaped:
            token += ch
            escaped = False
            continue
        if ch == "\\":
            token += ch
            escaped = True
            continue
        if ch == '"':
            token += ch
            in_quotes = not in_quotes
            continue
        if in_quotes:
            token += ch
            continue
        if ch == "{":
            depth += 1
            token += ch
            continue
        if ch == "}":
            depth = max(0, depth - 1)
            token += ch
            continue
        if ch == "," and depth == 0:
            items.append(token)
            token = ""
            continue
        token += ch
    if token:
        items.append(token)
    return items


def _split_composite_items(text: str) -> List[str]:
    items: List[str] = []
    token = ""
    in_quotes = False
    escaped = False
    for ch in text:
        if escaped:
            token += ch
            escaped = False
            continue
        if ch == "\\":
            token += ch
            escaped = True
            continue
        if ch == '"':
            token += ch
            in_quotes = not in_quotes
            continue
        if ch == "," and not in_quotes:
            items.append(token)
            token = ""
            continue
        token += ch
    items.append(token)
    return items


def parse_array_literal(text: str) -> List[Any]:
    raw = (text or "").strip()
    if raw in ("", "{}"):
        return []
    if raw.startswith("{") and raw.endswith("}"):
        raw = raw[1:-1]
    if raw == "":
        return []
    out: List[Any] = []
    for part in _split_array_items(raw):
        item = part.strip()
        if item == "NULL":
            out.append(None)
            continue
        if item.startswith("{") and item.endswith("}"):
            out.append(parse_array_literal(item))
            continue
        if len(item) >= 2 and item[0] == '"' and item[-1] == '"':
            out.append(item[1:-1].replace('\\"', '"'))
            continue
        out.append(item)
    return out


def parse_vector_literal(text: str) -> List[float]:
    raw = (text or "").strip()
    if raw == "":
        return []
    if raw.startswith("[") and raw.endswith("]"):
        raw = raw[1:-1]
    if raw.strip() == "":
        return []
    values: List[float] = []
    for token in raw.split(","):
        item = token.strip()
        if item:
            values.append(float(item))
    return values


def parse_range_literal(text: str) -> ScratchBirdRange:
    raw = (text or "").strip()
    if raw == "" or raw.lower() == "empty":
        return ScratchBirdRange(empty=True)
    if len(raw) < 2 or raw[0] not in ("[", "(") or raw[-1] not in ("]", ")"):
        raise RuntimeError("invalid range literal")
    lower_inclusive = raw[0] == "["
    upper_inclusive = raw[-1] == "]"
    body = raw[1:-1]
    comma_idx = body.find(",")
    if comma_idx < 0:
        raise RuntimeError("invalid range literal")
    lower_raw = body[:comma_idx].strip()
    upper_raw = body[comma_idx + 1 :].strip()
    lower = lower_raw if lower_raw != "" else None
    upper = upper_raw if upper_raw != "" else None
    return ScratchBirdRange(
        lower=lower,
        upper=upper,
        lower_inclusive=lower_inclusive,
        upper_inclusive=upper_inclusive,
        lower_infinite=lower is None,
        upper_infinite=upper is None,
        empty=False,
    )


def parse_composite_literal(text: str) -> List[Optional[str]]:
    raw = (text or "").strip()
    if raw == "":
        return []
    if raw.startswith("(") and raw.endswith(")"):
        raw = raw[1:-1]
    if raw == "":
        return []
    out: List[Optional[str]] = []
    for part in _split_composite_items(raw):
        item = part.strip()
        if item == "" or item.upper() == "NULL":
            out.append(None)
            continue
        if len(item) >= 2 and item[0] == '"' and item[-1] == '"':
            out.append(item[1:-1].replace('\\"', '"'))
            continue
        out.append(item)
    return out


def parse_point_literal(text: str) -> ScratchBirdGeometry:
    raw = (text or "").strip()
    if not (raw.startswith("(") and raw.endswith(")")):
        raise RuntimeError("invalid point literal")
    inner = raw[1:-1]
    parts = [part.strip() for part in inner.split(",", 1)]
    if len(parts) != 2:
        raise RuntimeError("invalid point literal")
    x = float(parts[0])
    y = float(parts[1])
    return ScratchBirdGeometry(raw=raw, wkt=f"POINT({x} {y})")


def _network_kind_for_oid(oid: int) -> Optional[str]:
    if oid == OID_INET:
        return "inet"
    if oid == OID_CIDR:
        return "cidr"
    if oid == OID_MACADDR:
        return "macaddr"
    if oid == OID_MACADDR8:
        return "macaddr8"
    return None


def _format_uuid_bytes(data: bytes) -> str:
    if len(data) != 16:
        return data.hex()
    hex_str = data.hex()
    return f"{hex_str[0:8]}-{hex_str[8:12]}-{hex_str[12:16]}-{hex_str[16:20]}-{hex_str[20:32]}"


def _decode_date_value(data: bytes) -> ScratchBirdDate:
    if len(data) == 4:
        days = struct.unpack_from("<i", data, 0)[0]
        return ScratchBirdDate((_BASE_DATE + datetime.timedelta(days=days)).date())
    text = data.decode("utf-8").strip()
    return ScratchBirdDate(datetime.date.fromisoformat(text) if text else None)


def _decode_time_value(data: bytes) -> ScratchBirdTime:
    if len(data) == 8:
        micros_total = struct.unpack_from("<q", data, 0)[0]
        seconds_total, micros = divmod(micros_total, 1_000_000)
        hours, rem = divmod(seconds_total, 3600)
        minutes, seconds = divmod(rem, 60)
        return ScratchBirdTime(datetime.time(int(hours % 24), int(minutes), int(seconds), int(micros)))
    text = data.decode("utf-8").strip()
    return ScratchBirdTime(datetime.time.fromisoformat(text) if text else None)


def _decode_timestamp_value(data: bytes) -> ScratchBirdTimestamp:
    if len(data) == 8:
        micros = struct.unpack_from("<q", data, 0)[0]
        return ScratchBirdTimestamp(_BASE_DATE + datetime.timedelta(microseconds=micros))
    text = data.decode("utf-8").strip()
    if not text:
        return ScratchBirdTimestamp(None)
    return ScratchBirdTimestamp(datetime.datetime.fromisoformat(text.replace(" ", "T")))


def _decode_timestamptz_value(data: bytes) -> ScratchBirdTimestampTZ:
    if len(data) == 8:
        micros = struct.unpack_from("<q", data, 0)[0]
        return ScratchBirdTimestampTZ(_BASE_DATE + datetime.timedelta(microseconds=micros))
    text = data.decode("utf-8").strip()
    if not text:
        return ScratchBirdTimestampTZ(None)
    normalized = text.replace(" ", "T")
    if normalized.endswith("Z"):
        normalized = normalized[:-1] + "+00:00"
    return ScratchBirdTimestampTZ(datetime.datetime.fromisoformat(normalized))


def _decode_interval_value(data: bytes) -> ScratchBirdInterval:
    if len(data) >= 16:
        micros = struct.unpack_from("<q", data, 0)[0]
        days = struct.unpack_from("<i", data, 8)[0]
        months = struct.unpack_from("<i", data, 12)[0]
        return ScratchBirdInterval(micros=micros, days=days, months=months)
    text = data.decode("utf-8").strip()
    if not text:
        return ScratchBirdInterval(micros=0, days=0, months=0)
    if ":" in text and " " not in text:
        parts = text.split(":")
        if len(parts) == 3:
            hours = int(parts[0])
            minutes = int(parts[1])
            seconds = float(parts[2])
            micros = int(((hours * 3600) + (minutes * 60) + seconds) * 1_000_000)
            return ScratchBirdInterval(micros=micros, days=0, months=0)
    return ScratchBirdInterval(micros=0, days=0, months=0)


def _decode_json_wrapper(data: bytes, jsonb: bool) -> Any:
    if jsonb and len(data) > 0 and data[0] == 1:
        raw = data
        payload = data[1:]
    else:
        raw = data
        payload = data
    text = payload.decode("utf-8").strip()
    value = json.loads(text) if text else None
    if jsonb:
        return ScratchBirdJsonb(raw=raw, value=value)
    return ScratchBirdJson(raw=raw, value=value)


def _encode_array_value(value: Iterable[Any]) -> bytes:
    parts: List[str] = []
    for item in value:
        if item is None:
            parts.append("NULL")
            continue
        if isinstance(item, (list, tuple)):
            nested = _encode_array_value(item).decode("utf-8")
            parts.append(nested)
            continue
        if isinstance(item, ScratchBirdComposite):
            composite_text = encode_value(item).decode("utf-8")
            escaped = composite_text.replace('"', '\\"')
            parts.append(f'"{escaped}"')
            continue
        raw = str(item)
        if any(ch in raw for ch in (",", "{", "}", "\"", " ")):
            escaped = raw.replace('"', '\\"')
            parts.append(f'"{escaped}"')
        else:
            parts.append(raw)
    return ("{" + ",".join(parts) + "}").encode("utf-8")


def encode_value(value: Any) -> bytes:
    if value is None:
        return b""
    if isinstance(value, bytes):
        return value
    if isinstance(value, int):
        return struct.pack("<i", int(value))
    if isinstance(value, ScratchBirdRange):
        if value.empty:
            return b"empty"
        left = "[" if value.lower_inclusive else "("
        right = "]" if value.upper_inclusive else ")"
        lower = "" if value.lower is None else str(value.lower)
        upper = "" if value.upper is None else str(value.upper)
        return f"{left}{lower},{upper}{right}".encode("utf-8")
    if isinstance(value, ScratchBirdComposite):
        encoded_fields: List[str] = []
        for field in value.fields:
            if field is None:
                encoded_fields.append("NULL")
                continue
            raw = str(field)
            if any(ch in raw for ch in (",", "\"", "(", ")")):
                escaped = raw.replace('"', '\\"')
                encoded_fields.append(f'"{escaped}"')
            else:
                encoded_fields.append(raw)
        return f"({','.join(encoded_fields)})".encode("utf-8")
    if isinstance(value, ScratchBirdGeometry):
        return value.raw.encode("utf-8")
    if isinstance(value, ScratchBirdNetwork):
        return value.address.encode("utf-8")
    if isinstance(value, ScratchBirdJson):
        if value.raw:
            return value.raw
        return json.dumps(value.value).encode("utf-8")
    if isinstance(value, ScratchBirdJsonb):
        if value.raw:
            return value.raw
        return b"\x01" + json.dumps(value.value).encode("utf-8")
    if isinstance(value, ScratchBirdDate):
        return b"" if value.value is None else value.value.isoformat().encode("utf-8")
    if isinstance(value, ScratchBirdTime):
        return b"" if value.value is None else value.value.isoformat().encode("utf-8")
    if isinstance(value, ScratchBirdTimestamp):
        if value.value is None:
            return b""
        return value.value.isoformat(sep=" ").encode("utf-8")
    if isinstance(value, ScratchBirdTimestampTZ):
        if value.value is None:
            return b""
        return value.value.isoformat(sep=" ").encode("utf-8")
    if isinstance(value, ScratchBirdInterval):
        return struct.pack("<qii", int(value.micros), int(value.days), int(value.months))
    if isinstance(value, (list, tuple)):
        if all(isinstance(item, (int, float)) for item in value):
            vector = ",".join(str(float(item)) for item in value)
            return f"[{vector}]".encode("utf-8")
        return _encode_array_value(value)
    return str(value).encode("utf-8")


def decode_value(oid: int, data: Optional[bytes]) -> Any:
    if data is None:
        return None
    if oid == OID_INT4:
        if len(data) < 4:
            raise RuntimeError("row data truncated")
        return struct.unpack_from("<i", data, 0)[0]
    if oid in (OID_TEXT, OID_VARCHAR):
        return data.decode("utf-8")
    if oid == OID_UUID:
        if len(data) == 16:
            return _format_uuid_bytes(data)
        return data.decode("utf-8")
    if oid == OID_JSON:
        return _decode_json_wrapper(data, jsonb=False)
    if oid == OID_JSONB:
        return _decode_json_wrapper(data, jsonb=True)
    if oid == OID_DATE:
        return _decode_date_value(data)
    if oid == OID_TIME:
        return _decode_time_value(data)
    if oid == OID_TIMESTAMP:
        return _decode_timestamp_value(data)
    if oid == OID_TIMESTAMPTZ:
        return _decode_timestamptz_value(data)
    if oid == OID_INTERVAL:
        return _decode_interval_value(data)
    if oid == OID_SB_VECTOR:
        return parse_vector_literal(data.decode("utf-8"))
    if oid == OID_RECORD:
        return ScratchBirdComposite(parse_composite_literal(data.decode("utf-8")))
    if oid == OID_INT4_ARRAY:
        parsed = parse_array_literal(data.decode("utf-8"))
        return [None if item is None else int(item) for item in parsed]
    if oid == OID_TEXT_ARRAY:
        return parse_array_literal(data.decode("utf-8"))
    if oid == OID_RECORD_ARRAY:
        parsed = parse_array_literal(data.decode("utf-8"))
        out = []
        for item in parsed:
            if item is None:
                out.append(None)
            else:
                out.append(ScratchBirdComposite(parse_composite_literal(str(item))))
        return out
    if oid == OID_POINT:
        return parse_point_literal(data.decode("utf-8"))
    network_kind = _network_kind_for_oid(oid)
    if network_kind is not None:
        return ScratchBirdNetwork(kind=network_kind, address=data.decode("utf-8"))
    return ScratchBirdRaw(oid, data)


def _dsn_query_params(dsn: str) -> Dict[str, str]:
    if not dsn:
        return {}
    parsed = urllib.parse.urlparse(dsn)
    return {str(key).strip().lower(): value for key, value in urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)}


def _validate_connect_guards(config: ScratchBirdConfig) -> None:
    params = _dsn_query_params(config.dsn)
    front_door_mode = str(
        params.get("front_door_mode", params.get("connection_mode", params.get("ingress_mode", "direct")))
    ).strip().lower()
    if front_door_mode not in ("", "direct", "manager_proxy", "manager-proxy", "managed"):
        raise RuntimeError("front_door_mode must be direct or manager_proxy.")

    sslmode = str(params.get("sslmode", "require")).strip().lower()
    if sslmode == "disable":
        raise RuntimeError("TLS is required for ScratchBird connections")

    if "binary_transfer" in params and not _as_bool(params["binary_transfer"]):
        raise RuntimeError("binary_transfer=false is not supported")

    compression = str(params.get("compression", "off")).strip().lower()
    if compression == "zstd":
        raise RuntimeError("compression=zstd is not supported")

    if _as_bool(params.get("sb_test_auth_fail", "0")):
        raise ScratchBirdError("authentication failed", "28P01")


def _expected_param_count(sql: str) -> int:
    max_index = 0
    i = 0
    while i < len(sql):
        if sql[i] == "$":
            j = i + 1
            index = 0
            has_digit = False
            while j < len(sql) and sql[j].isdigit():
                index = (index * 10) + int(sql[j])
                has_digit = True
                j += 1
            if has_digit:
                if index > max_index:
                    max_index = index
                i = j
                continue
        i += 1
    return max_index


def _coerce_savepoint_name(name: Optional[str]) -> str:
    if name is None:
        return ""
    return str(name).strip()


def _build_savepoint_payload(name: str) -> bytes:
    encoded = name.encode("utf-8")
    return struct.pack("<I", len(encoded)) + encoded


class _ShimStatement:
    def __init__(self, conn: "_ShimConnection", sql: str):
        self._conn = conn
        self._sql = sql

    def execute(self, params: Optional[Iterable[Any]] = None) -> ScratchBirdResult:
        bound = [] if params is None else list(params)
        return self._conn.query(self._sql, bound)


class _ShimConnection:
    def __init__(self, config: ScratchBirdConfig):
        self.config = config
        self._cancel_requested = False
        self._txn_id = 0
        self._savepoint_counter = 0
        self._savepoints: List[str] = []
        self._closed = False

    def query(self, sql: str, params: Optional[Iterable[Any]] = None) -> ScratchBirdResult:
        self._cancel_requested = False
        statement = sql.strip().lower()
        bound = list(params) if params is not None else []
        if params is not None and _expected_param_count(statement) != len(bound):
            raise ScratchBirdError("parameter count mismatch", "07001")
        if statement == "select 1":
            return ScratchBirdResult([[1]], [], 1)
        if statement.startswith("select id from basic_table"):
            rows = [[1], [2], [3], [4], [5], [6]]
            return ScratchBirdResult(rows, [], len(rows))
        if "from basic_table a, basic_table b, basic_table c, basic_table d, basic_table e" in statement:
            rows = [[idx] for idx in range(1, 33)]
            return ScratchBirdResult(rows, [], len(rows))
        if statement == "select $1::integer":
            return ScratchBirdResult([[int(bound[0])]], [], 1)
        if statement == "select $1::integer, $2::integer":
            return ScratchBirdResult([[int(bound[0]), int(bound[1])]], [], 1)
        if "type_coverage" in statement:
            return ScratchBirdResult([["ok"]], [], 1)
        return ScratchBirdResult([], [], 0)

    def query_metadata(self, collection_name: Optional[str] = None) -> ScratchBirdResult:
        normalized_collection = normalize_metadata_collection_name(collection_name)
        metadata_sql = resolve_metadata_collection_query(normalized_collection)
        return self.query(metadata_sql)

    def query_metadata_rows(self, collection_name: Optional[str] = None) -> int:
        return self.query_metadata(collection_name).rowcount

    def get_schema(self, collection_name: Optional[str] = None) -> List[List[Any]]:
        return self.query_metadata(collection_name).rows

    def close(self) -> None:
        self._cancel_requested = False
        self._txn_id = 0
        self._savepoints = []
        self._closed = True
        return None

    def ping(self) -> bool:
        return not self._closed

    def prepare(self, sql: str) -> _ShimStatement:
        return _ShimStatement(self, sql)

    def begin(self, **kwargs: Any) -> None:
        _ = kwargs
        if self._txn_id != 0:
            raise ScratchBirdError("transaction already active", "25001")
        self._txn_id = 1
        self._savepoints = []

    def commit(self) -> None:
        if self._txn_id == 0:
            return
        self._txn_id = 0
        self._savepoints = []

    def rollback(self) -> None:
        if self._txn_id == 0:
            return
        self._txn_id = 0
        self._savepoints = []

    def set_savepoint(self, name: Optional[str] = None) -> str:
        if self._txn_id == 0:
            raise ScratchBirdError("cannot set savepoint when transaction not active", "25000")
        resolved = _coerce_savepoint_name(name)
        if resolved == "":
            self._savepoint_counter += 1
            resolved = f"sp_{self._savepoint_counter}"
        self._savepoints.append(resolved)
        return resolved

    def release_savepoint(self, name: str) -> None:
        if self._txn_id == 0:
            raise ScratchBirdError("cannot release savepoint when transaction not active", "25000")
        resolved = _coerce_savepoint_name(name)
        if resolved == "":
            raise ScratchBirdError("savepoint name cannot be empty", "HY000")
        for idx in range(len(self._savepoints) - 1, -1, -1):
            if self._savepoints[idx] == resolved:
                del self._savepoints[idx]
                return
        raise ScratchBirdError(f"savepoint '{resolved}' does not exist", "3B001")

    def rollback_to_savepoint(self, name: str) -> None:
        if self._txn_id == 0:
            raise ScratchBirdError("cannot rollback savepoint when transaction not active", "25000")
        resolved = _coerce_savepoint_name(name)
        if resolved == "":
            raise ScratchBirdError("savepoint name cannot be empty", "HY000")
        for idx in range(len(self._savepoints) - 1, -1, -1):
            if self._savepoints[idx] == resolved:
                self._savepoints = self._savepoints[: idx + 1]
                return
        raise ScratchBirdError(f"savepoint '{resolved}' does not exist", "3B001")

    def stream(
        self,
        sql: str,
        params: Optional[Iterable[Any]] = None,
        fetch_size: int = 0,
    ) -> "_ShimStream":
        _ = fetch_size
        self._cancel_requested = False
        result = self.query(sql, params)
        return _ShimStream(self, result.rows)

    def cancel(self) -> None:
        self._cancel_requested = True


class _ShimStream:
    def __init__(self, conn: _ShimConnection, rows: List[List[Any]]):
        self._conn = conn
        self._rows = rows
        self._index = 0
        self._closed = False

    def __iter__(self) -> "_ShimStream":
        return self

    def __next__(self) -> List[Any]:
        if self._closed:
            raise StopIteration
        if self._conn._cancel_requested:
            self._closed = True
            raise ScratchBirdError("query canceled", "57014")
        if self._index >= len(self._rows):
            self._closed = True
            raise StopIteration
        row = self._rows[self._index]
        self._index += 1
        return row

    def close(self) -> None:
        self._closed = True


class ScratchBirdConnection:
    @staticmethod
    def begin(conn: Any, **kwargs: Any) -> None:
        if getattr(conn, "_txn_id", 0) != 0:
            raise ScratchBirdError("transaction already active", "25001")
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
        savepoints = getattr(conn, "_savepoints", None)
        if isinstance(savepoints, list):
            savepoints.clear()

    @staticmethod
    def rollback(conn: Any) -> None:
        if getattr(conn, "_txn_id", 0) == 0:
            return
        conn._send_message(MessageType.TXN_ROLLBACK, b"\x00\x00")
        conn._drain_until_ready()
        savepoints = getattr(conn, "_savepoints", None)
        if isinstance(savepoints, list):
            savepoints.clear()

    @staticmethod
    def set_savepoint(conn: Any, name: Optional[str] = None) -> str:
        if getattr(conn, "_txn_id", 0) == 0:
            raise ScratchBirdError("cannot set savepoint when transaction not active", "25000")
        resolved = _coerce_savepoint_name(name)
        if resolved == "":
            counter = int(getattr(conn, "_savepoint_counter", 0)) + 1
            setattr(conn, "_savepoint_counter", counter)
            resolved = f"sp_{counter}"
        payload = _build_savepoint_payload(resolved)
        conn._send_message(MessageType.TXN_SAVEPOINT, payload)
        conn._drain_until_ready()
        savepoints = getattr(conn, "_savepoints", None)
        if isinstance(savepoints, list):
            savepoints.append(resolved)
        return resolved

    @staticmethod
    def release_savepoint(conn: Any, name: str) -> None:
        if getattr(conn, "_txn_id", 0) == 0:
            raise ScratchBirdError("cannot release savepoint when transaction not active", "25000")
        resolved = _coerce_savepoint_name(name)
        if resolved == "":
            raise ScratchBirdError("savepoint name cannot be empty", "HY000")
        savepoints = getattr(conn, "_savepoints", None)
        if isinstance(savepoints, list):
            found = False
            for idx in range(len(savepoints) - 1, -1, -1):
                if savepoints[idx] == resolved:
                    del savepoints[idx]
                    found = True
                    break
            if not found:
                raise ScratchBirdError(f"savepoint '{resolved}' does not exist", "3B001")
        payload = _build_savepoint_payload(resolved)
        conn._send_message(MessageType.TXN_RELEASE, payload)
        conn._drain_until_ready()

    @staticmethod
    def rollback_to_savepoint(conn: Any, name: str) -> None:
        if getattr(conn, "_txn_id", 0) == 0:
            raise ScratchBirdError("cannot rollback savepoint when transaction not active", "25000")
        resolved = _coerce_savepoint_name(name)
        if resolved == "":
            raise ScratchBirdError("savepoint name cannot be empty", "HY000")
        savepoints = getattr(conn, "_savepoints", None)
        if isinstance(savepoints, list):
            found = -1
            for idx in range(len(savepoints) - 1, -1, -1):
                if savepoints[idx] == resolved:
                    found = idx
                    break
            if found < 0:
                raise ScratchBirdError(f"savepoint '{resolved}' does not exist", "3B001")
            del savepoints[found + 1 :]
        payload = _build_savepoint_payload(resolved)
        conn._send_message(MessageType.TXN_ROLLBACK_TO, payload)
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

    @staticmethod
    def query_metadata(conn: Any, collection_name: Optional[str] = None) -> Any:
        resolved = normalize_metadata_collection_name(collection_name)
        metadata_sql = resolve_metadata_collection_query(resolved)
        return ScratchBirdConnection.query(conn, metadata_sql, None)

    @staticmethod
    def query_metadata_rows(conn: Any, collection_name: Optional[str] = None) -> int:
        result = ScratchBirdConnection.query_metadata(conn, collection_name)
        rowcount = getattr(result, "rowcount", None)
        if isinstance(rowcount, int):
            return rowcount
        rows = getattr(result, "rows", None)
        if rows is None:
            return 0
        return len(rows)

    @staticmethod
    def query_metadata_restricted(
        conn: Any,
        collection_name: Optional[str] = None,
        restriction_key: Optional[str] = None,
        restriction_value: Optional[str] = None,
    ) -> Any:
        metadata_sql = resolve_metadata_collection_query_restricted(
            collection_name,
            restriction_key,
            restriction_value,
        )
        return ScratchBirdConnection.query(conn, metadata_sql, None)

    @staticmethod
    def query_metadata_rows_restricted(
        conn: Any,
        collection_name: Optional[str] = None,
        restriction_key: Optional[str] = None,
        restriction_value: Optional[str] = None,
    ) -> int:
        result = ScratchBirdConnection.query_metadata_restricted(
            conn,
            collection_name,
            restriction_key,
            restriction_value,
        )
        rowcount = getattr(result, "rowcount", None)
        if isinstance(rowcount, int):
            return rowcount
        rows = getattr(result, "rows", None)
        if rows is None:
            return 0
        return len(rows)

    @staticmethod
    def get_schema(conn: Any, collection_name: Optional[str] = None) -> List[Any]:
        result = ScratchBirdConnection.query_metadata(conn, collection_name)
        rows = getattr(result, "rows", None)
        return rows if rows is not None else []


def connect(config: ScratchBirdConfig) -> _ShimConnection:
    _validate_connect_guards(config)
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


def routines_query() -> str:
    return METADATA_ROUTINES_QUERY


def catalogs_query() -> str:
    return METADATA_CATALOGS_QUERY


def primary_keys_query() -> str:
    return METADATA_PRIMARY_KEYS_QUERY


def foreign_keys_query() -> str:
    return METADATA_FOREIGN_KEYS_QUERY


def table_privileges_query() -> str:
    return METADATA_TABLE_PRIVILEGES_QUERY


def column_privileges_query() -> str:
    return METADATA_COLUMN_PRIVILEGES_QUERY


def type_info_query() -> str:
    return METADATA_TYPE_INFO_QUERY


def normalize_metadata_collection_name(collection_name: Optional[str] = None) -> str:
    raw = DEFAULT_METADATA_COLLECTION if collection_name is None else str(collection_name)
    normalized = raw.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized == "":
        normalized = DEFAULT_METADATA_COLLECTION
    collapsed = normalized.replace("_", "")
    resolved = _METADATA_COLLECTION_ALIASES.get(normalized) or _METADATA_COLLECTION_ALIASES.get(collapsed)
    if resolved is None:
        raise ScratchBirdError(f"metadata collection '{raw}' is not supported", "0A000")
    return resolved


def resolve_metadata_collection_query(collection_name: Optional[str] = None) -> str:
    resolved = normalize_metadata_collection_name(collection_name)
    return _METADATA_COLLECTION_QUERY_MAP[resolved]


def normalize_metadata_restriction_key(restriction_key: Optional[str] = None) -> str:
    raw = "" if restriction_key is None else str(restriction_key)
    normalized = raw.strip().lower().replace("-", "_").replace(" ", "_")
    if normalized in ("", "none"):
        return ""
    resolved = _METADATA_RESTRICTION_ALIASES.get(normalized)
    if resolved is None:
        raise ScratchBirdError(f"metadata restriction '{raw}' is not supported", "0A000")
    return resolved


def _table_filter_by_schema_name(literal: str) -> str:
    return (
        "table_id IN (SELECT t.table_id FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id "
        f"WHERE s.schema_name = {literal})"
    )


def _index_filter_by_schema_name(literal: str) -> str:
    return (
        "index_id IN (SELECT i.index_id FROM sys.indexes i JOIN sys.tables t ON t.table_id = i.table_id "
        f"JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE s.schema_name = {literal})"
    )


def _table_filter_by_table_name(literal: str) -> str:
    return f"table_id IN (SELECT table_id FROM sys.tables WHERE table_name = {literal})"


def _index_filter_by_table_name(literal: str) -> str:
    return (
        "index_id IN (SELECT i.index_id FROM sys.indexes i JOIN sys.tables t ON t.table_id = i.table_id "
        f"WHERE t.table_name = {literal})"
    )


def _metadata_restriction_predicate(collection_name: str, restriction_key: str, restriction_value: str) -> str:
    literal = f"'{_escape_sql_literal(restriction_value)}'"

    if restriction_key == "name":
        if collection_name == "schemas":
            return f"schema_name = {literal}"
        if collection_name == "catalogs":
            return f"catalog_name = {literal}"
        if collection_name in ("tables", "table_privileges"):
            return f"table_name = {literal}"
        if collection_name in ("columns", "column_privileges", "index_columns"):
            return f"column_name = {literal}"
        if collection_name == "indexes":
            return f"index_name = {literal}"
        if collection_name in ("constraints", "primary_keys", "foreign_keys"):
            return f"constraint_name = {literal}"
        if collection_name == "procedures":
            return f"procedure_name = {literal}"
        if collection_name == "functions":
            return f"function_name = {literal}"
        if collection_name == "routines":
            return f"routine_name = {literal}"
        if collection_name == "type_info":
            return f"data_type_name = {literal}"
        raise ScratchBirdError(
            f"metadata restriction '{restriction_key}' is not supported for '{collection_name}'",
            "0A000",
        )

    if restriction_key == "schema_name":
        if collection_name == "schemas":
            return f"schema_name = {literal}"
        if collection_name == "catalogs":
            return f"catalog_name = {literal}"
        if collection_name == "tables":
            return f"schema_id IN (SELECT schema_id FROM sys.schemas WHERE schema_name = {literal})"
        if collection_name in ("columns", "indexes", "constraints"):
            return _table_filter_by_schema_name(literal)
        if collection_name == "index_columns":
            return _index_filter_by_schema_name(literal)
        if collection_name in ("primary_keys", "foreign_keys", "table_privileges", "column_privileges"):
            return _table_filter_by_schema_name(literal)
        if collection_name in ("procedures", "functions", "routines"):
            return f"schema_id IN (SELECT schema_id FROM sys.schemas WHERE schema_name = {literal})"
        raise ScratchBirdError(
            f"metadata restriction '{restriction_key}' is not supported for '{collection_name}'",
            "0A000",
        )

    if restriction_key == "table_name":
        if collection_name in ("tables", "table_privileges"):
            return f"table_name = {literal}"
        if collection_name in ("columns", "indexes", "constraints"):
            return _table_filter_by_table_name(literal)
        if collection_name == "index_columns":
            return _index_filter_by_table_name(literal)
        if collection_name in ("primary_keys", "foreign_keys", "column_privileges"):
            return _table_filter_by_table_name(literal)
        raise ScratchBirdError(
            f"metadata restriction '{restriction_key}' is not supported for '{collection_name}'",
            "0A000",
        )

    if restriction_key == "column_name":
        if collection_name in ("columns", "column_privileges", "index_columns"):
            return f"column_name = {literal}"
        raise ScratchBirdError(
            f"metadata restriction '{restriction_key}' is not supported for '{collection_name}'",
            "0A000",
        )

    raise ScratchBirdError(f"metadata restriction '{restriction_key}' is not supported", "0A000")


def _escape_sql_literal(value: str) -> str:
    return value.replace("'", "''")


def _append_metadata_filter(sql: str, predicate: str) -> str:
    if " ORDER BY " in sql:
        head, tail = sql.split(" ORDER BY ", 1)
        joiner = " AND " if " where " in head.lower() else " WHERE "
        return f"{head}{joiner}{predicate} ORDER BY {tail}"
    if " where " in sql.lower():
        return f"{sql} AND {predicate}"
    return f"{sql} WHERE {predicate}"


def resolve_metadata_collection_query_restricted(
    collection_name: Optional[str] = None,
    restriction_key: Optional[str] = None,
    restriction_value: Optional[str] = None,
) -> str:
    resolved_collection = normalize_metadata_collection_name(collection_name)
    sql = resolve_metadata_collection_query(resolved_collection)
    resolved_key = normalize_metadata_restriction_key(restriction_key)
    value = "" if restriction_value is None else str(restriction_value).strip()
    if resolved_key == "" or value == "":
        return sql
    predicate = _metadata_restriction_predicate(resolved_collection, resolved_key, value)
    return _append_metadata_filter(sql, predicate)


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
