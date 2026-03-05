from __future__ import annotations

import pathlib
import struct
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "src"))

import scratchbird


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def test_parse_array_literal_nested_and_null() -> None:
    parsed = scratchbird.parse_array_literal('{1,{2,3},NULL,"quoted"}')
    _require(parsed == ["1", ["2", "3"], None, "quoted"], "array literal parse mismatch")


def test_parse_vector_literal_and_decode_vector_oid() -> None:
    parsed = scratchbird.parse_vector_literal("[1.5, 2, -3]")
    _require(parsed == [1.5, 2.0, -3.0], "vector literal parse mismatch")

    decoded = scratchbird.decode_value(scratchbird.OID_SB_VECTOR, b"[4,5,6]")
    _require(decoded == [4.0, 5.0, 6.0], "vector decode mismatch")


def test_parse_range_literal_edges() -> None:
    r1 = scratchbird.parse_range_literal("[1,10)")
    _require(r1.lower == "1" and r1.upper == "10", "range bounds mismatch")
    _require(r1.lower_inclusive is True and r1.upper_inclusive is False, "range inclusivity mismatch")

    r2 = scratchbird.parse_range_literal("(,10]")
    _require(r2.lower is None and r2.upper == "10", "range infinite lower mismatch")
    _require(r2.lower_infinite is True and r2.upper_infinite is False, "range infinite flags mismatch")

    empty = scratchbird.parse_range_literal("empty")
    _require(empty.empty is True, "empty range mismatch")


def test_decode_unknown_oid_returns_raw() -> None:
    raw = scratchbird.decode_value(99999, b"abc")
    _require(isinstance(raw, scratchbird.ScratchBirdRaw), "unknown oid should return ScratchBirdRaw")
    _require(raw.oid == 99999 and raw.data == b"abc", "raw fallback content mismatch")


def test_decode_int4_truncation_error() -> None:
    try:
        scratchbird.decode_value(scratchbird.OID_INT4, b"\x01")
        raise RuntimeError("expected truncation failure")
    except RuntimeError as exc:
        _require("row data truncated" in str(exc), "truncation message mismatch")


def test_encode_value_shapes() -> None:
    encoded_int = scratchbird.encode_value(7)
    _require(encoded_int == struct.pack("<i", 7), "int encode mismatch")

    encoded_vec = scratchbird.encode_value([1, 2.5, -3])
    _require(encoded_vec == b"[1.0,2.5,-3.0]", "vector encode mismatch")

    encoded_range = scratchbird.encode_value(
        scratchbird.ScratchBirdRange(
            lower="1",
            upper="9",
            lower_inclusive=True,
            upper_inclusive=False,
        )
    )
    _require(encoded_range == b"[1,9)", "range encode mismatch")


def main() -> None:
    test_parse_array_literal_nested_and_null()
    test_parse_vector_literal_and_decode_vector_oid()
    test_parse_range_literal_edges()
    test_decode_unknown_oid_returns_raw()
    test_decode_int4_truncation_error()
    test_encode_value_shapes()
    print("Mojo type codec tests OK")


if __name__ == "__main__":
    main()
