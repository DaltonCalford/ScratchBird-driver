# S2 TXN/EXEC Implementation (DLB-PYTHON-003)

Scope: `tracks/alpha/drivers/python` lane only.

## Changes

- Added lane-local transaction guardrails in `src/scratchbird/connection.py`:
  - `begin()` now rejects nested begin when a transaction is already active.
  - `commit()` and `rollback()` now no-op when no transaction is active (avoids unnecessary wire calls on txn id `0`).
  - `savepoint()`, `release_savepoint()`, and `rollback_to_savepoint()` now require an active transaction and validate savepoint names.
- Added execution parity helper in `src/scratchbird/connection.py`:
  - `native_sql(sql, params=None)` returns normalized/native SQL rewrite without executing.
- Hardened parameter error behavior for execution paths in `src/scratchbird/connection.py`:
  - `_execute_query()` now maps SQL normalization `ValueError` into DB-API `ProgrammingError`.
- Added lane-local execution input validation in `src/scratchbird/cursor.py`:
  - `executemany(..., seq_of_params)` now raises `ProgrammingError` when `seq_of_params` is `None`.
- Implemented command-complete generated-key parity in `src/scratchbird/connection.py` and `src/scratchbird/cursor.py`:
  - `ResultStream` now captures `COMMAND_COMPLETE.last_id` as `lastrowid`.
  - Cursor drain paths (`fetchone()` completion and `executemany()`) now propagate stream `lastrowid` consistently.
- Fixed named parameter normalization around cast syntax in `src/scratchbird/sql.py`:
  - `::` cast markers are no longer misinterpreted as named placeholders.
- Added targeted tests:
  - Extended `tests/test_txn_exec_parity.py` with result-stream `last_id` to `lastrowid` propagation and `executemany` final-`lastrowid` behavior checks.
  - Extended `tests/test_sql.py` with a cast-syntax rewrite regression test.
- Updated TXN/EXEC rows in `BASELINE_REQUIREMENT_MAPPING.md` with current evidence and status notes.

## Tests Run

1. `pytest -q tests/test_txn_exec_parity.py tests/test_sql.py tests/test_connection_auth_protocol.py`
- Result: PASS (`25 passed`)

## TXN Status

- Recommendation: `PARTIAL`
- Reason:
  - Explicit begin/commit/rollback/savepoint APIs now have deterministic local guardrails and focused unit coverage.
  - Remaining gap: `autocommit` remains local-state only (no explicit wire/session toggle behavior in this lane), and TXN behavior is not yet covered by live integration transaction tests.

## EXEC Status

- Recommendation: `PARTIAL`
- Reason:
  - Execution normalization and dispatch parity improved via `native_sql`, normalization-error mapping to DB-API `ProgrammingError`, cast-safe named parameter rewrite, explicit `executemany` input validation, and `COMMAND_COMPLETE.last_id` to `cursor.lastrowid` propagation across execute/executemany paths, all with lane-local tests.
  - Remaining gap: no first-class batch API, multi-result traversal API, dedicated generated-keys result-set API, or callable/routine API.

## Remaining Gaps

- TXN:
  - Wire-level autocommit/session parity is not implemented as a dedicated transaction-state operation.
  - No integration test that validates transaction lifecycle against a live server in this lane.
- EXEC:
  - No dedicated batch execution API surface.
  - No dedicated multi-result traversal API surface.
  - No dedicated generated-keys result-set API (current coverage is `lastrowid` parity from command-complete metadata only).
  - No dedicated callable/routine execution API.
