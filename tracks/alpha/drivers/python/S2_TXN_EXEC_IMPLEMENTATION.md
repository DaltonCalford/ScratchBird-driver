# S2 TXN/EXEC Implementation (DLB-PYTHON-003)

Scope: `tracks/alpha/drivers/python` lane only.

## Changes

- Added lane-local transaction guardrails in `src/scratchbird/connection.py`:
  - `begin()` now rejects nested begin when a transaction is already active.
  - `commit()` and `rollback()` now no-op when no transaction is active (avoids unnecessary wire calls on txn id `0`).
  - `savepoint()`, `release_savepoint()`, and `rollback_to_savepoint()` now require an active transaction and validate savepoint names.
- Added JDBC-aligned autocommit transition behavior in `src/scratchbird/connection.py`:
  - `autocommit=True` now commits an active transaction before switching modes.
  - No-op transitions (`autocommit` already set to requested value) now short-circuit.
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
- Added callable and multi-result execution parity in `src/scratchbird/connection.py`, `src/scratchbird/cursor.py`, and `src/scratchbird/sql.py`:
  - `native_callable_sql(sql, params=None)` and `call(sql, params=None)` now expose callable normalization/execution on `Connection`.
  - `Cursor.callproc(procname, params=None)` now routes through callable normalization with placeholder rewriting.
  - `ResultStream` now tracks result-set boundaries and exposes next-result navigation; `Cursor.nextset()` now advances across result sets.
- Added first-class batch execution summaries in `src/scratchbird/connection.py`:
  - `execute_batch(sql, batch_params)` now returns per-item summaries (`index`, `rowCount`, `fields`, `command`, `lastId`) plus `totalRowCount`.
  - `query_batch(sql, batch_params)` now aliases `execute_batch(...)`.
- Added first-class multi-result summary helpers in `src/scratchbird/connection.py`:
  - `query_multi(sql, params)` now returns all result sets as structured summaries (`rows`, `rowCount`, `fields`, `command`, `lastId`).
  - `execute_multi(sql, params)` now aliases `query_multi(...)`.
- Added status-message propagation in `src/scratchbird/connection.py` and `src/scratchbird/cursor.py`:
  - `ResultStream` now captures `COMMAND_COMPLETE.tag` as `command`.
  - Cursor drain paths now expose that as `cursor.statusmessage`.
- Added dedicated generated-keys result-set API in `src/scratchbird/cursor.py` and `src/scratchbird/connection.py`:
  - `Cursor.get_generated_keys()` now returns a generated-keys result-set object (`fetchone/fetchmany/fetchall`, `description`, `rowcount`).
  - Generated keys are accumulated across execute, executemany, and multi-result boundaries.
  - `Connection.execute_with_generated_keys(sql, params)` now provides convenience execution + generated-keys retrieval.
- Added callable and next-result tests:
  - Extended `tests/test_txn_exec_parity.py` with `Connection.call`, `native_callable_sql`, and `Cursor.callproc/nextset` coverage.
  - Extended `tests/test_sql.py` with JDBC escape callable normalization coverage.
- Added batch/statusmessage tests:
  - Extended `tests/test_txn_exec_parity.py` with `Connection.execute_batch/query_batch` coverage and status-message assertions.
- Added generated-keys tests:
  - Extended `tests/test_txn_exec_parity.py` with `Cursor.get_generated_keys` and `Connection.execute_with_generated_keys` coverage, including multi-result accumulation.
- Added multi-result summary tests:
  - Extended `tests/test_txn_exec_parity.py` with `Connection.query_multi/execute_multi` coverage.
- Updated TXN/EXEC rows in `BASELINE_REQUIREMENT_MAPPING.md` with current evidence and status notes.

## Tests Run

1. `PYTHONPATH=src pytest -q`
- Result: PASS (`68 passed, 4 skipped`)

2. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests/test_txn_exec_parity.py`
- Result: PASS (`35 passed`)

## TXN Status

- Recommendation: `PARTIAL`
- Reason:
  - Explicit begin/commit/rollback/savepoint APIs now have deterministic local guardrails and focused unit coverage.
  - `autocommit` transition semantics now align better with JDBC (`autocommit=True` commits an active transaction before mode switch).
  - Remaining gap: no explicit wire/session autocommit toggle operation is implemented in this lane, and TXN behavior is not yet covered by live integration transaction tests.

## EXEC Status

- Recommendation: `PARTIAL`
- Reason:
  - Execution normalization and dispatch parity now includes `native_sql`/`native_callable_sql`, callable execution (`Connection.call` / `Cursor.callproc`), normalization-error mapping to DB-API `ProgrammingError`, cast-safe named parameter rewrite, explicit `executemany` input validation, first-class batch summaries (`execute_batch`/`query_batch`), first-class multi-result summaries (`query_multi`/`execute_multi`), dedicated generated-keys result-set retrieval (`get_generated_keys` / `execute_with_generated_keys`), generated-key propagation (`COMMAND_COMPLETE.last_id` to `cursor.lastrowid`), command-tag propagation (`cursor.statusmessage`), and multi-result traversal via `Cursor.nextset()`, all with lane-local tests.
  - Remaining gap: limited live integration depth.

## Remaining Gaps

- TXN:
  - Wire-level autocommit/session parity is not implemented as a dedicated transaction-state operation.
  - No integration test that validates transaction lifecycle against a live server in this lane.
- EXEC:
  - Live integration coverage depth remains limited for extended execution surfaces.
