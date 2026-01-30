# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
"""Type helpers and defaults for SBWP v1.1."""

from __future__ import annotations

import datetime as _dt
import decimal as _decimal
import ipaddress as _ip
import json as _json
import struct
import uuid
from dataclasses import dataclass
from typing import Any, Optional

from .protocol import ParamValue

FORMAT_TEXT = 0
FORMAT_BINARY = 1

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

_RANGE_EMPTY = 0x01
_RANGE_LB_INC = 0x02
_RANGE_UB_INC = 0x04
_RANGE_LB_INF = 0x08
_RANGE_UB_INF = 0x10


@dataclass
class Jsonb:
    raw: bytes
    value: Optional[Any] = None


@dataclass
class Json:
    raw: bytes
    value: Optional[Any] = None


@dataclass
class Geometry:
    wkb: bytes
    srid: Optional[int] = None
    wkt: Optional[str] = None


@dataclass
class Range:
    lower: Optional[Any] = None
    upper: Optional[Any] = None
    lower_inclusive: bool = False
    upper_inclusive: bool = False
    lower_infinite: bool = False
    upper_infinite: bool = False
    empty: bool = False
    range_oid: Optional[int] = None


@dataclass
class CompositeField:
    oid: int
    value: Optional[Any] = None
    data: Optional[bytes] = None


@dataclass
class Composite:
    fields: list[CompositeField]
    type_oid: int = OID_RECORD


@dataclass
class RawValue:
    oid: int
    data: bytes


def encode_param(value: Any) -> tuple[ParamValue, int]:
    if value is None:
        return ParamValue(FORMAT_BINARY, None), 0
    if isinstance(value, Composite):
        data, oid = _encode_composite(value)
        return ParamValue(FORMAT_BINARY, data), oid
    if isinstance(value, RawValue):
        return ParamValue(FORMAT_BINARY, value.data), value.oid
    if isinstance(value, Jsonb):
        raw = value.raw
        if (not raw) and value.value is not None:
            raw = _json.dumps(value.value, ensure_ascii=True).encode("utf-8")
        if not raw:
            raise ValueError("JSONB requires raw payload")
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(raw)), OID_JSONB
    if isinstance(value, Json):
        raw = value.raw
        if (not raw) and value.value is not None:
            raw = _json.dumps(value.value, ensure_ascii=True).encode("utf-8")
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(raw)), OID_JSON
    if isinstance(value, Geometry):
        if not value.wkb:
            raise ValueError("geometry requires WKB payload")
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(value.wkb)), OID_POINT
    if isinstance(value, Range):
        data, oid = _encode_range(value)
        return ParamValue(FORMAT_BINARY, data), oid
    if isinstance(value, bool):
        return ParamValue(FORMAT_BINARY, b"\x01" if value else b"\x00"), OID_BOOL
    if isinstance(value, int):
        if -2**31 <= value <= 2**31 - 1:
            return ParamValue(FORMAT_BINARY, struct.pack("<i", value)), OID_INT4
        if -2**63 <= value <= 2**63 - 1:
            return ParamValue(FORMAT_BINARY, struct.pack("<q", value)), OID_INT8
        raise ValueError("integer out of range for int64")
    if isinstance(value, float):
        return ParamValue(FORMAT_BINARY, struct.pack("<d", value)), OID_FLOAT8
    if isinstance(value, _decimal.Decimal):
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(str(value).encode("utf-8"))), OID_NUMERIC
    if isinstance(value, _dt.datetime):
        if value.tzinfo is not None:
            return ParamValue(FORMAT_BINARY, _encode_timestamp(value.astimezone(_dt.timezone.utc))), OID_TIMESTAMPTZ
        return ParamValue(FORMAT_BINARY, _encode_timestamp(value.replace(tzinfo=_dt.timezone.utc))), OID_TIMESTAMP
    if isinstance(value, _dt.date) and not isinstance(value, _dt.datetime):
        return ParamValue(FORMAT_BINARY, _encode_date(value)), OID_DATE
    if isinstance(value, _dt.time):
        return ParamValue(FORMAT_BINARY, _encode_time(value)), OID_TIME
    if isinstance(value, _dt.timedelta):
        micros = int(value.total_seconds() * 1_000_000)
        data = struct.pack("<qii", micros, 0, 0)
        return ParamValue(FORMAT_BINARY, data), OID_INTERVAL
    if isinstance(value, uuid.UUID):
        return ParamValue(FORMAT_BINARY, value.bytes), OID_UUID
    if isinstance(value, (bytes, bytearray, memoryview)):
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(bytes(value))), OID_BYTEA
    if isinstance(value, (_ip.IPv4Address, _ip.IPv6Address)):
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(str(value).encode("utf-8"))), OID_INET
    if isinstance(value, (_ip.IPv4Network, _ip.IPv6Network)):
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(str(value).encode("utf-8"))), OID_CIDR
    if isinstance(value, (list, tuple)):
        if _is_vector_candidate(value):
            text = _format_vector_literal(value)
            return ParamValue(FORMAT_BINARY, _encode_length_prefixed(text.encode("utf-8"))), OID_SB_VECTOR
        text = _format_array_literal(value)
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(text.encode("utf-8"))), 0
    if isinstance(value, str):
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(value.encode("utf-8"))), OID_TEXT
    if isinstance(value, dict):
        encoded = _json.dumps(value, ensure_ascii=True).encode("utf-8")
        return ParamValue(FORMAT_BINARY, _encode_length_prefixed(encoded)), OID_JSON
    raise ValueError("unsupported parameter type")


def decode_value(type_oid: int, data: Optional[bytes], format_code: int) -> Any:
    if data is None:
        return None
    if format_code == FORMAT_TEXT:
        return _decode_text_value(data)
    return _decode_binary_value(type_oid, data)


def _decode_binary_value(type_oid: int, data: bytes) -> Any:
    if type_oid == OID_BOOL:
        return data[:1] == b"\x01"
    if type_oid == OID_INT2:
        return struct.unpack_from("<h", data)[0]
    if type_oid == OID_INT4:
        return struct.unpack_from("<i", data)[0]
    if type_oid == OID_INT8:
        return struct.unpack_from("<q", data)[0]
    if type_oid == OID_FLOAT4:
        return struct.unpack_from("<f", data)[0]
    if type_oid == OID_FLOAT8:
        return struct.unpack_from("<d", data)[0]
    if type_oid == OID_NUMERIC:
        return _decimal.Decimal(_strip_length_prefix(data).decode("utf-8", errors="replace"))
    if type_oid == OID_MONEY:
        cents = struct.unpack_from("<q", data)[0]
        return _decimal.Decimal(cents) / _decimal.Decimal(100)
    if type_oid in (OID_TEXT, OID_VARCHAR, OID_CHAR, OID_BPCHAR, OID_JSON, OID_XML, OID_TSVECTOR, OID_TSQUERY):
        return _strip_length_prefix(data).decode("utf-8", errors="replace")
    if type_oid == OID_JSONB:
        return Jsonb(_strip_length_prefix(data), None)
    if type_oid == OID_BYTEA:
        return _strip_length_prefix(data)
    if type_oid == OID_DATE:
        return _decode_date(data)
    if type_oid == OID_TIME:
        return _decode_time(data)
    if type_oid == OID_TIMESTAMP:
        return _decode_timestamp(data)
    if type_oid == OID_TIMESTAMPTZ:
        return _decode_timestamp(data)
    if type_oid == OID_INTERVAL:
        months, days, micros = struct.unpack_from("<iiq", data)
        return {"months": months, "days": days, "micros": micros}
    if type_oid == OID_UUID:
        return uuid.UUID(bytes=data[:16])
    if type_oid in (OID_INET, OID_CIDR, OID_MACADDR, OID_MACADDR8):
        return _strip_length_prefix(data).decode("utf-8", errors="replace")
    if type_oid in (OID_INT4RANGE, OID_INT8RANGE, OID_NUMRANGE, OID_TSRANGE, OID_TSTZRANGE, OID_DATERANGE):
        return _decode_range(type_oid, data)
    if type_oid == OID_SB_VECTOR:
        return _parse_vector_literal(_strip_length_prefix(data).decode("utf-8", errors="replace"))
    if type_oid in (OID_POINT, OID_LSEG, OID_PATH, OID_BOX, OID_POLYGON, OID_LINE, OID_CIRCLE):
        return Geometry(_strip_length_prefix(data))
    if type_oid == OID_RECORD:
        return _decode_composite(data)
    return data


def _decode_text_value(data: bytes) -> str:
    if len(data) >= 4:
        length = struct.unpack_from("<I", data, 0)[0]
        if 0 <= length <= len(data) - 4:
            return data[4 : 4 + length].decode("utf-8", errors="replace")
    return data.decode("utf-8", errors="replace")


def _encode_length_prefixed(data: bytes) -> bytes:
    return struct.pack("<I", len(data)) + data


def _encode_composite(value: Composite) -> tuple[bytes, int]:
    fields = value.fields or []
    buf = bytearray()
    buf += struct.pack("<i", len(fields))
    for field in fields:
        field_oid = field.oid
        data = None
        if field.data is not None:
            data = field.data
        elif field.value is not None:
            param, oid = encode_param(field.value)
            if field_oid == 0:
                field_oid = oid
            if param.is_null:
                data = None
            else:
                data = param.data or b""

        if field_oid == 0:
            raise ValueError("composite field OID is required")
        buf += struct.pack("<I", field_oid)
        if data is None:
            buf += struct.pack("<i", -1)
            continue
        buf += struct.pack("<i", len(data))
        buf += data
    type_oid = value.type_oid or OID_RECORD
    return bytes(buf), type_oid


def _decode_composite(data: bytes) -> Composite:
    if len(data) < 4:
        return Composite(fields=[])
    count = struct.unpack_from("<i", data, 0)[0]
    offset = 4
    fields: list[CompositeField] = []
    for _ in range(count):
        if offset + 8 > len(data):
            break
        oid = struct.unpack_from("<I", data, offset)[0]
        offset += 4
        length = struct.unpack_from("<i", data, offset)[0]
        offset += 4
        if length < 0:
            fields.append(CompositeField(oid=oid, value=None, data=None))
            continue
        if offset + length > len(data):
            break
        raw = data[offset : offset + length]
        offset += length
        value = _decode_binary_value(oid, raw)
        fields.append(CompositeField(oid=oid, value=value, data=raw))
    return Composite(fields=fields)


def _strip_length_prefix(data: bytes) -> bytes:
    if len(data) < 4:
        return data
    length = struct.unpack_from("<I", data, 0)[0]
    if length <= len(data) - 4:
        return data[4 : 4 + length]
    return data


def _encode_date(value: _dt.date) -> bytes:
    base = _dt.date(2000, 1, 1)
    days = (value - base).days
    return struct.pack("<i", days)


def _encode_time(value: _dt.time) -> bytes:
    micros = (
        (value.hour * 3600 + value.minute * 60 + value.second) * 1_000_000
        + value.microsecond
    )
    return struct.pack("<q", micros)


def _encode_timestamp(value: _dt.datetime) -> bytes:
    base = _dt.datetime(2000, 1, 1, tzinfo=_dt.timezone.utc)
    delta = value - base
    micros = int(delta.total_seconds() * 1_000_000)
    return struct.pack("<q", micros)


def _decode_date(data: bytes) -> _dt.date:
    days = struct.unpack_from("<i", data)[0]
    return _dt.date(2000, 1, 1) + _dt.timedelta(days=days)


def _decode_time(data: bytes) -> _dt.time:
    micros = struct.unpack_from("<q", data)[0]
    secs, micro = divmod(micros, 1_000_000)
    hours, rem = divmod(secs, 3600)
    mins, secs = divmod(rem, 60)
    return _dt.time(int(hours % 24), int(mins), int(secs), int(micro))


def _decode_timestamp(data: bytes) -> _dt.datetime:
    micros = struct.unpack_from("<q", data)[0]
    base = _dt.datetime(2000, 1, 1, tzinfo=_dt.timezone.utc)
    return base + _dt.timedelta(microseconds=micros)


def _is_vector_candidate(values: Any) -> bool:
    if not values:
        return False
    for item in values:
        if isinstance(item, (list, tuple)):
            return False
        if not isinstance(item, (int, float)):
            return False
    return True


def _format_array_literal(values) -> str:
    items = [_format_array_item(item) for item in values]
    return "{" + ",".join(items) + "}"


def _format_array_item(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, (list, tuple)):
        return _format_array_literal(value)
    if isinstance(value, str):
        return '"' + value.replace('"', "\\\"") + '"'
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _parse_array_literal(text: str):
    text = text.strip()
    if text == "" or text == "{}":
        return []
    if text.startswith("{") and text.endswith("}"):
        text = text[1:-1]
    return _split_array_items(text)


def _split_array_items(text: str):
    items = []
    buf = []
    depth = 0
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "{":
            depth += 1
            buf.append(ch)
        elif ch == "}":
            depth = max(0, depth - 1)
            buf.append(ch)
        elif ch == "," and depth == 0:
            items.append(_parse_array_item("".join(buf)))
            buf = []
        else:
            buf.append(ch)
        i += 1
    if buf or text:
        items.append(_parse_array_item("".join(buf)))
    return items


def _parse_array_item(raw: str):
    token = raw.strip()
    if token == "":
        return ""
    if token.upper() == "NULL":
        return None
    if token.startswith("{") and token.endswith("}"):
        return _parse_array_literal(token)
    if token.startswith("[") and token.endswith("]"):
        return _parse_vector_literal(token)
    if token.lower() in ("true", "false"):
        return token.lower() == "true"
    try:
        if "." in token:
            return float(token)
        return int(token)
    except ValueError:
        return token


def _format_vector_literal(values) -> str:
    parts = [str(float(value)) for value in values]
    return "[" + ",".join(parts) + "]"


def _parse_vector_literal(text: str):
    text = text.strip()
    if text.startswith("[") and text.endswith("]"):
        text = text[1:-1]
    if text.strip() == "":
        return []
    parts = [part.strip() for part in text.split(",")]
    values = []
    for part in parts:
        if part == "":
            continue
        try:
            values.append(float(part))
        except ValueError:
            values.append(part)
    return values


def _encode_range(range_value: Range) -> tuple[bytes, int]:
    oid = range_value.range_oid or _infer_range_oid(range_value)
    flags = 0
    if range_value.empty:
        flags |= _RANGE_EMPTY
    if range_value.lower_inclusive:
        flags |= _RANGE_LB_INC
    if range_value.upper_inclusive:
        flags |= _RANGE_UB_INC
    if range_value.lower_infinite:
        flags |= _RANGE_LB_INF
    if range_value.upper_infinite:
        flags |= _RANGE_UB_INF
    out = bytearray()
    out.append(flags)
    out += b"\x00\x00\x00"
    if not range_value.empty and not range_value.lower_infinite:
        bound = _encode_range_bound(oid, range_value.lower)
        out += struct.pack("<i", len(bound))
        out += bound
    if not range_value.empty and not range_value.upper_infinite:
        bound = _encode_range_bound(oid, range_value.upper)
        out += struct.pack("<i", len(bound))
        out += bound
    return bytes(out), oid


def _infer_range_oid(range_value: Range) -> int:
    if range_value.range_oid:
        return range_value.range_oid
    sample = range_value.lower if range_value.lower is not None else range_value.upper
    if isinstance(sample, _decimal.Decimal):
        return OID_NUMRANGE
    if isinstance(sample, _dt.date) and not isinstance(sample, _dt.datetime):
        return OID_DATERANGE
    if isinstance(sample, _dt.datetime):
        if sample.tzinfo is not None:
            return OID_TSTZRANGE
        return OID_TSRANGE
    if isinstance(sample, int):
        return OID_INT4RANGE if -2**31 <= sample <= 2**31 - 1 else OID_INT8RANGE
    raise ValueError("range type cannot be inferred")


def _encode_range_bound(range_oid: int, value: Any) -> bytes:
    if range_oid == OID_INT4RANGE:
        return struct.pack("<i", int(value))
    if range_oid == OID_INT8RANGE:
        return struct.pack("<q", int(value))
    if range_oid == OID_NUMRANGE:
        return _encode_length_prefixed(str(value).encode("utf-8"))
    if range_oid == OID_DATERANGE:
        return _encode_date(value)
    if range_oid == OID_TSRANGE:
        return _encode_timestamp(value.replace(tzinfo=_dt.timezone.utc))
    if range_oid == OID_TSTZRANGE:
        return _encode_timestamp(value.astimezone(_dt.timezone.utc))
    raise ValueError("unsupported range type")


def _decode_range(range_oid: int, data: bytes) -> Range:
    if len(data) < 4:
        return Range()
    flags = data[0]
    offset = 4
    result = Range(
        lower_inclusive=bool(flags & _RANGE_LB_INC),
        upper_inclusive=bool(flags & _RANGE_UB_INC),
        lower_infinite=bool(flags & _RANGE_LB_INF),
        upper_infinite=bool(flags & _RANGE_UB_INF),
        empty=bool(flags & _RANGE_EMPTY),
        range_oid=range_oid,
    )
    if result.empty:
        return result
    if not result.lower_infinite:
        if offset + 4 > len(data):
            return result
        length = struct.unpack_from("<i", data, offset)[0]
        offset += 4
        bound = data[offset : offset + length]
        offset += length
        result.lower = _decode_range_bound(range_oid, bound)
    if not result.upper_infinite:
        if offset + 4 > len(data):
            return result
        length = struct.unpack_from("<i", data, offset)[0]
        offset += 4
        bound = data[offset : offset + length]
        result.upper = _decode_range_bound(range_oid, bound)
    return result


def _decode_range_bound(range_oid: int, data: bytes) -> Any:
    if range_oid == OID_INT4RANGE:
        return struct.unpack_from("<i", data)[0]
    if range_oid == OID_INT8RANGE:
        return struct.unpack_from("<q", data)[0]
    if range_oid == OID_NUMRANGE:
        return _decimal.Decimal(_strip_length_prefix(data).decode("utf-8", errors="replace"))
    if range_oid == OID_DATERANGE:
        return _decode_date(data)
    if range_oid == OID_TSRANGE:
        return _decode_timestamp(data).replace(tzinfo=None)
    if range_oid == OID_TSTZRANGE:
        return _decode_timestamp(data)
    return None


def type_name(type_oid: int) -> str:
    return {
        OID_BOOL: "boolean",
        OID_INT2: "int2",
        OID_INT4: "int4",
        OID_INT8: "int8",
        OID_FLOAT4: "float4",
        OID_FLOAT8: "float8",
        OID_NUMERIC: "numeric",
        OID_MONEY: "money",
        OID_TEXT: "text",
        OID_VARCHAR: "varchar",
        OID_CHAR: "char",
        OID_BPCHAR: "char",
        OID_BYTEA: "bytea",
        OID_DATE: "date",
        OID_TIME: "time",
        OID_TIMESTAMP: "timestamp",
        OID_TIMESTAMPTZ: "timestamptz",
        OID_INTERVAL: "interval",
        OID_UUID: "uuid",
        OID_JSON: "json",
        OID_JSONB: "jsonb",
        OID_XML: "xml",
        OID_INET: "inet",
        OID_CIDR: "cidr",
        OID_MACADDR: "macaddr",
        OID_MACADDR8: "macaddr8",
        OID_TSVECTOR: "tsvector",
        OID_TSQUERY: "tsquery",
        OID_INT4RANGE: "int4range",
        OID_INT8RANGE: "int8range",
        OID_NUMRANGE: "numrange",
        OID_TSRANGE: "tsrange",
        OID_TSTZRANGE: "tstzrange",
        OID_DATERANGE: "daterange",
        OID_SB_VECTOR: "vector",
    }.get(type_oid, "unknown")
