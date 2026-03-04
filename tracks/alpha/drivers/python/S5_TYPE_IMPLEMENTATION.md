# S5 Type Implementation (DLB-PYTHON-006)

Scope: `tracks/alpha/drivers/python` lane only.

## Changes

- Extended type codec parity in `src/scratchbird/types.py` for `TIMETZ`:
  - `encode_param(...)` now treats offset-aware `datetime.time` (`tzinfo` set) as `OID_TIMETZ` and emits a deterministic 12-byte binary payload (`<qi`: micros since midnight + zone seconds west of UTC).
  - `_decode_binary_value(...)` now supports `OID_TIMETZ` via `_decode_timetz(...)`.
  - `_decode_timetz(...)` handles:
    - 12-byte payloads with zone displacement.
    - Backward-compatible 8-byte payloads (UTC fallback when zone bytes are absent).
  - Text decode now routes through `_decode_text_typed_value(...)`, with `OID_TIMETZ` parsing to offset-aware `datetime.time` via ISO offset parsing.
  - `type_name(...)` now maps `OID_TIMETZ` to `"timetz"`.
- Added JDBC-style typed array parity in `src/scratchbird/types.py`:
  - Non-vector Python list/tuple payloads now infer stable array OIDs (for bool/bytea/int/float/text/date/time/timetz/timestamp/timestamptz/numeric/uuid families) instead of always using OID `0`.
  - `_decode_binary_value(...)` now recognizes typed array OIDs and decodes them through array-literal parsing.
  - Array literal parsing now handles quoted and escaped string elements while preserving nested-array behavior.
  - `type_name(...)` now includes array OID names (`text[]`, `boolean[]`, `timetz[]`, etc.).
- Added deterministic tests in `tests/test_types.py`:
  - `test_encode_timetz_uses_binary_layout_and_zone_seconds_west`
  - `test_decode_timetz_binary_payload_roundtrip`
  - `test_decode_timetz_binary_payload_supports_legacy_8byte_form`
  - `test_decode_timetz_text_payload_to_offset_time`
  - `test_type_name_includes_timetz`
  - `test_encode_string_array_infers_text_array_oid`
  - `test_encode_bool_array_infers_boolean_array_oid`
  - `test_decode_int4_array_literal_payload`
  - `test_decode_text_array_literal_with_quotes_and_nested_arrays`
  - `test_type_name_includes_array_names`

## Tests Run

1. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests/test_types.py`
- Result: PASS (`18 passed`)

2. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests`
- Result: PASS (`163 passed, 27 skipped, 1 warning`)

## TYPE Status Recommendation

- Recommendation: `PARTIAL`
- Reason:
  - Deterministic type parity now explicitly includes `TIMETZ` encode/decode behavior (binary and text) aligned with JDBC lane expectations for zone-aware time payloads.
  - Deterministic type parity now also includes typed array OID inference/decode behavior with quoted-string/nested-array literal parsing coverage.
  - Existing scalar/json/range/composite/vector paths remain covered by unit tests and env-gated integration checks.
  - Remaining gap: deeper live type coverage is still env-gated and can be skipped when `SCRATCHBIRD_TEST_DSN` is not set.
