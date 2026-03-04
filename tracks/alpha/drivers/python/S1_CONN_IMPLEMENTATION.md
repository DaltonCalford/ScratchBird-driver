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
- Added runtime session-schema parity helpers in `src/scratchbird/connection.py`:
  - `get_session_schema()` returns the normalized active session-schema setting.
  - `set_session_schema(schema)` updates local session-schema state and executes `SET SCHEMA`/`SET SEARCH_PATH` (resetting `None` to `public`).
- Added JDBC-style liveness helper in `src/scratchbird/connection.py`:
  - `is_valid(timeout_ms=0)` returns a boolean health probe backed by `ping()`.
  - Closed connections return `False`; negative timeout raises `ProgrammingError`.
  - When possible, timeout is applied/restored via socket timeout mutation around `ping()`.
- Added targeted unit tests in `tests/test_connection_auth_protocol.py` covering:
  - semicolon DSN parsing
  - alias-based connection config normalization
  - auth startup field capture
  - startup auth plugin parameter assembly
  - invalid auth method namespace handling
  - manager proxy token fail-fast behavior
- Added targeted unit tests in `tests/test_txn_exec_parity.py` covering:
  - runtime session-schema set/get behavior
  - session-schema reset-to-public behavior
  - unchanged session-schema no-op behavior
  - non-string session-schema input validation
- Added env-gated live integration coverage in `tests/test_integration.py`:
  - `test_session_schema_runtime_integration` validates runtime session-schema transitions against a live endpoint when `SCRATCHBIRD_TEST_DSN` is configured.
  - `test_connection_ping_integration` validates wire-level connection liveness checks against a live endpoint when `SCRATCHBIRD_TEST_DSN` is configured.
  - `test_connection_is_valid_integration` validates boolean liveness probing and closed-connection behavior against a live endpoint when `SCRATCHBIRD_TEST_DSN` is configured.

## Test Commands Run

1. `pytest -q tests/test_connection_auth_protocol.py`
- Result: PASS (`6 passed`)

2. `pytest -q tests/test_sql.py tests/test_types.py`
- Result: PASS (`5 passed`)

3. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests/test_txn_exec_parity.py`
- Result: PASS (`41 passed`)

4. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests/test_sql.py tracks/alpha/drivers/python/tests/test_connection_auth_protocol.py tracks/alpha/drivers/python/tests/test_txn_exec_parity.py tracks/alpha/drivers/python/tests/test_integration.py tracks/alpha/drivers/python/tests/test_types.py`
- Result: PASS (`68 passed, 14 skipped`)

5. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests/test_integration.py`
- Result: PASS (`26 skipped`) when `SCRATCHBIRD_TEST_DSN` is not configured.

6. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests`
- Result: PASS (`149 passed, 26 skipped`)

## CONN Status Recommendation

- Recommendation: `PARTIAL`

## Remaining Gaps

- Lane is still explicitly limited to `protocol=native`; non-native protocol options are rejected.
- Lane is TLS-only (`sslmode=disable` is rejected).
- `binary_transfer=false` and `compression=zstd` remain intentionally unsupported in this lane.
- Connection/auth behavior still relies on limited integration coverage in this lane (`tests/test_integration.py` requires external environment variables and a running server).
