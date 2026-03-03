# S1 CONN Implementation (DLB-PYTHON-002)

Scope: `tracks/alpha/drivers/python` only.

## What Changed

- Extended DSN key-value parsing to accept both whitespace and semicolon separators in `src/scratchbird/dsn.py`.
- Expanded connection config alias handling in `src/scratchbird/connection.py` for:
  - `dbname` -> `database`
  - `username` -> `user`
  - `connecttimeout` -> `connect_timeout`
  - `sockettimeout` -> `socket_timeout`
  - `applicationname` -> `application_name`
  - `binarytransfer` -> `binary_transfer`
- Added auth startup config fields on `ConnectionConfig`:
  - `auth_method_id`
  - `auth_payload_json`
  - `auth_payload_b64`
  - `auth_provider_profile`
- Added `_build_startup_params()` and wired `_startup_and_auth()` to apply protocol auth plugin selection (`apply_auth_plugin_selection`) before sending `STARTUP`.
- Added fail-fast validation in `_connect()` so `front_door_mode=manager_proxy` without `manager_auth_token` errors before any socket connect attempt.
- Added targeted unit tests in `tests/test_connection_auth_protocol.py` covering:
  - semicolon DSN parsing
  - alias-based connection config normalization
  - auth startup field capture
  - startup auth plugin parameter assembly
  - invalid auth method namespace handling
  - manager proxy token fail-fast behavior

## Test Commands Run

1. `pytest -q tests/test_connection_auth_protocol.py`
- Result: PASS (`6 passed`)

2. `pytest -q tests/test_sql.py tests/test_types.py`
- Result: PASS (`5 passed`)

## CONN Status Recommendation

- Recommendation: `PARTIAL`

## Remaining Gaps

- Lane is still explicitly limited to `protocol=native`; non-native protocol options are rejected.
- Lane is TLS-only (`sslmode=disable` is rejected).
- `binary_transfer=false` and `compression=zstd` remain intentionally unsupported in this lane.
- Connection/auth behavior still relies on limited integration coverage in this lane (`tests/test_integration.py` requires external environment variables and a running server).
