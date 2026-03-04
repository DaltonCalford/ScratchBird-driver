# S2 TXN/EXEC Implementation (DLB-PHP-003)

Scope: `tracks/alpha/drivers/php` only.

## What Changed

- Added explicit transaction-state tracking and guards in `src/Connection.php`:
  - Added `inTransaction` state.
  - Added `requireActiveTransaction()` for `commit`, `rollback`, `savepoint`, `releaseSavepoint`, and `rollbackToSavepoint`.
  - Added savepoint-name validation via `normalizeSavepointName()`.
  - Added `applyTxnState()` wiring on READY/auth/parameter events.
- Added `ScratchBirdPDO::inTransaction()` passthrough in `src/ScratchBirdPDO.php`.
- Improved execution behavior in `src/Connection.php`:
  - `exec()` now uses simple-query flow and drains result stream to return command-complete affected rows.
- Added callable, batch, multi-result, and generated-key execution parity in `src/Connection.php`, `src/Statement.php`, `src/ResultStream.php`, `src/Sql.php`, and `src/ScratchBirdPDO.php`:
  - Callable normalization/translation: `nativeSql`, `nativeCallableSql`, and `call(...)`.
  - First-class batch summaries: `executeBatch(...)` and `queryBatch(...)` with per-item `index`, `rowCount`, `fields`, `command`, and `lastId`, plus `totalRowCount`.
  - First-class multi-result summaries: `queryMulti(...)` and `executeMulti(...)`.
  - Generated-key retrieval: `executeWithGeneratedKeys(...)`, `Statement::getGeneratedKeys()`, and command-complete last-id propagation to `Connection::lastInsertId(...)`.
  - Statement/result traversal parity: `Statement::nextRowset()` / `nextset()` backed by result-set boundary support in `ResultStream`.
- Added new targeted wire-fixture tests in `tests/ConnectionTxnExecTest.php` for:
  - commit guard when no transaction is active,
  - transaction lifecycle and wire message types,
  - savepoint name validation,
  - `exec()` rows-affected and error-path behavior,
  - multi-result traversal (`queryMulti`),
  - batch summaries (`executeBatch`),
  - generated-key accumulation (`executeWithGeneratedKeys`),
  - callable translation dispatch (`call`) and native SQL/callable normalization APIs.
- Added callable SQL normalization tests in `tests/SqlTest.php`.

## Test Commands Run

1. `php vendor/bin/phpunit tests/ConnectionTxnExecTest.php tests/SqlTest.php tests/ConnectionConnTest.php tests/ProtocolConnAuthTest.php tests/ConfigTest.php`
- Result: PASS (`OK (31 tests, 101 assertions)`).
2. `php vendor/bin/phpunit tests`
- Result: PASS (`OK, but some tests were skipped!` / `49 tests, 131 assertions, 10 skipped`).
  - Integration suite now includes env-gated tests for:
    - `queryMulti` / `executeMulti` live result-set separation,
    - `executeBatch` batch summaries,
    - JDBC callable escape execution (`call`),
    - statement `nextRowset` traversal across multi-result responses.

## Status Recommendation

- `TXN`: `PARTIAL`
- `EXEC`: `PARTIAL`

## Remaining Gaps

- TXN semantics are better guarded locally but still need broader end-to-end server behavior validation under integration fixtures.
- EXEC now includes lane-local callable, batch, multi-result traversal, generated-key capture, and translation-surface parity, with expanded env-gated integration checks for multi-result/batch/call/rowset traversal; status remains `Partial` due broader advanced execution stress coverage and limited non-gated live depth.
