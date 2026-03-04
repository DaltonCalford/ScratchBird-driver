# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
from __future__ import annotations

import datetime as dt
import struct

from scratchbird.types import (
    Composite,
    CompositeField,
    FORMAT_TEXT,
    OID_INT4,
    OID_INT4RANGE,
    OID_INTERVAL,
    OID_JSONB,
    OID_RECORD,
    OID_SB_VECTOR,
    OID_TIMETZ,
    FORMAT_BINARY,
    decode_value,
    encode_param,
    Jsonb,
    Range,
    type_name,
)


def test_decode_int4():
    raw = (42).to_bytes(4, byteorder="little", signed=True)
    assert decode_value(OID_INT4, raw, FORMAT_BINARY) == 42


def test_decode_jsonb():
    payload = b"{\"a\":1}"
    raw = len(payload).to_bytes(4, byteorder="little") + payload
    value = decode_value(OID_JSONB, raw, FORMAT_BINARY)
    assert isinstance(value, Jsonb)
    assert value.raw == payload


def test_decode_vector_literal():
    text = b"[1, 2.5]"
    raw = len(text).to_bytes(4, byteorder="little") + text
    assert decode_value(OID_SB_VECTOR, raw, FORMAT_BINARY) == [1.0, 2.5]


def test_encode_timedelta_uses_interval_binary_layout():
    param, oid = encode_param(dt.timedelta(days=2, seconds=3, microseconds=4))

    assert oid == OID_INTERVAL
    months, days, micros = struct.unpack("<iiq", param.data)
    assert months == 0
    assert days == 0
    assert micros == 172803000004


def test_decode_interval_binary_payload():
    raw = struct.pack("<iiq", 2, 3, 5_000_000)
    assert decode_value(OID_INTERVAL, raw, FORMAT_BINARY) == {
        "months": 2,
        "days": 3,
        "micros": 5_000_000,
    }


def test_encode_timetz_uses_binary_layout_and_zone_seconds_west():
    value = dt.time(12, 34, 56, 123000, tzinfo=dt.timezone(dt.timedelta(hours=5, minutes=30)))
    param, oid = encode_param(value)

    assert oid == OID_TIMETZ
    micros, zone_seconds_west = struct.unpack("<qi", param.data)
    assert micros == 45_296_123_000
    assert zone_seconds_west == -19_800


def test_decode_timetz_binary_payload_roundtrip():
    raw = struct.pack("<qi", 45_296_123_000, -19_800)
    decoded = decode_value(OID_TIMETZ, raw, FORMAT_BINARY)
    assert decoded == dt.time(12, 34, 56, 123000, tzinfo=dt.timezone(dt.timedelta(hours=5, minutes=30)))


def test_decode_timetz_binary_payload_supports_legacy_8byte_form():
    raw = struct.pack("<q", 3_661_000_000)
    decoded = decode_value(OID_TIMETZ, raw, FORMAT_BINARY)
    assert decoded == dt.time(1, 1, 1, tzinfo=dt.timezone.utc)


def test_decode_timetz_text_payload_to_offset_time():
    decoded = decode_value(OID_TIMETZ, b"08:09:10+03", FORMAT_TEXT)
    assert decoded == dt.time(8, 9, 10, tzinfo=dt.timezone(dt.timedelta(hours=3)))


def test_type_name_includes_timetz():
    assert type_name(OID_TIMETZ) == "timetz"


def test_encode_decode_range_roundtrip():
    param, oid = encode_param(
        Range(
            lower=1,
            upper=10,
            lower_inclusive=True,
            upper_inclusive=False,
            range_oid=OID_INT4RANGE,
        )
    )

    assert oid == OID_INT4RANGE
    value = decode_value(oid, param.data, FORMAT_BINARY)
    assert isinstance(value, Range)
    assert value.lower == 1
    assert value.upper == 10
    assert value.lower_inclusive is True
    assert value.upper_inclusive is False


def test_encode_decode_composite_roundtrip():
    param, oid = encode_param(
        Composite(
            fields=[
                CompositeField(oid=OID_INT4, value=7),
                CompositeField(oid=OID_JSONB, value=Jsonb(raw=b'{"a":1}')),
            ],
            type_oid=OID_RECORD,
        )
    )

    assert oid == OID_RECORD
    value = decode_value(oid, param.data, FORMAT_BINARY)
    assert isinstance(value, Composite)
    assert len(value.fields) == 2
    assert value.fields[0].oid == OID_INT4
    assert value.fields[0].value == 7
    assert value.fields[1].oid == OID_JSONB
    assert isinstance(value.fields[1].value, Jsonb)
    assert value.fields[1].value.raw == b'{"a":1}'


def test_encode_vector_candidate_roundtrip():
    param, oid = encode_param([1, 2.5, 3])

    assert oid == OID_SB_VECTOR
    assert decode_value(oid, param.data, FORMAT_BINARY) == [1.0, 2.5, 3.0]
