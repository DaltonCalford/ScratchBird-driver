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
- Added new targeted wire-fixture tests in `tests/ConnectionTxnExecTest.php` for:
  - commit guard when no transaction is active,
  - transaction lifecycle and wire message types,
  - savepoint name validation,
  - `exec()` rows-affected and error-path behavior.

## Test Commands Run

1. `php vendor/bin/phpunit tests/ConnectionTxnExecTest.php tests/ConnectionConnTest.php tests/ProtocolConnAuthTest.php tests/ConfigTest.php`
- Result: PASS (`OK (18 tests, 58 assertions)`).

## Status Recommendation

- `TXN`: `PARTIAL`
- `EXEC`: `PARTIAL`

## Remaining Gaps

- TXN semantics are better guarded locally but still need broader end-to-end server behavior validation under integration fixtures.
- EXEC covers row-count/error fixture paths, but multi-result and advanced execution parity remain incomplete in lane-local tests.
