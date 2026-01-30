# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
from __future__ import annotations

from scratchbird.types import (
    OID_INT4,
    OID_JSONB,
    OID_SB_VECTOR,
    FORMAT_BINARY,
    decode_value,
    Jsonb,
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
