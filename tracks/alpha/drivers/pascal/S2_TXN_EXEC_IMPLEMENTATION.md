# S2 TXN/EXEC Implementation (DLB-PASCAL-003)

Scope: `tracks/alpha/drivers/pascal` only.

## What Changed

- Added lane-local transaction guardrails in `src/ScratchBird.Client.pas`:
  - Added `EnsureConnected` (`08003`) and applied it to transaction begin and execution entry points.
  - `BeginTransactionEx` now rejects nested begin when `FTxnId <> 0` (`25000`, `transaction already active`).
  - `Commit`/`Rollback` now no-op when no active transaction (`FTxnId = 0`) to avoid unnecessary wire calls.
  - `Savepoint`/`ReleaseSavepoint`/`RollbackToSavepoint` now:
    - require non-blank savepoint names (`42601`, `savepoint name is required`),
    - require an active transaction (`25000`, `<op> requires an active transaction`).
  - `Disconnect` now clears local transaction/attachment state (`FTxnId := 0`, zero attachment bytes).
- Added execution input validation in `src/ScratchBird.Client.pas`:
  - Added `NormalizeSqlText`; `ExecSQLParams` and `ExecuteQueryParams` reject blank SQL early (`42601`, `SQL text is required`).
- Fixed execution SQL normalization parity in `src/ScratchBird.Sql.pas`:
  - `NormalizeNamedSql` now preserves PostgreSQL-style cast markers (`::`) and only treats `@name`/`:name` forms with identifier starts as named parameters.
- Added/updated lane tests:
  - New `tests/TxnExecParityTests.pas` for TXN guardrails and EXEC validation/normalization checks.
  - Updated `tests/SqlTests.pas` to current normalization APIs and added cast-syntax normalization coverage.
- Updated TXN/EXEC evidence and gaps in `BASELINE_REQUIREMENT_MAPPING.md`.

## Targeted Tests Run

1. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FE./tracks/alpha/drivers/pascal/tests ./tracks/alpha/drivers/pascal/tests/TxnExecParityTests.pas`
- Result: PASS (compile succeeded).

2. `./tracks/alpha/drivers/pascal/tests/TxnExecParityTests`
- Result: PASS (`TxnExecParityTests: OK`).

3. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FE./tracks/alpha/drivers/pascal/tests ./tracks/alpha/drivers/pascal/tests/SqlTests.pas`
- Result: PASS (compile succeeded).

4. `./tracks/alpha/drivers/pascal/tests/SqlTests`
- Result: PASS (`SqlTests: OK`).

## TXN Status

- Recommendation: `PARTIAL`

Rationale:
- Deterministic lane-local TXN guardrails now exist and are covered by dedicated tests (disconnected begin, no-active-txn commit/rollback behavior, savepoint active-txn and name validation, txn payload encoding checks).
- Remaining gaps prevent `MET`: no live server transaction lifecycle integration test coverage for begin/commit/rollback/savepoint and no adapter-surface parity for advanced transaction options exposed by `BeginTransactionEx`.

## EXEC Status

- Recommendation: `PARTIAL`

Rationale:
- Deterministic lane-local execution parity improved with blank SQL validation and cast-safe named-parameter normalization, with targeted unit coverage in `TxnExecParityTests` and `SqlTests`.
- Remaining gaps prevent `MET`: adapter `Prepare` methods are still placeholders, and there is no first-class lane API/test coverage for batch execution, multi-result traversal, or generated-key retrieval.

## Remaining Concrete Gaps

- TXN:
  - Add live integration tests for full transaction lifecycle against a running ScratchBird endpoint.
  - Surface advanced transaction option parity at adapter APIs (currently client-level only).
- EXEC:
  - Implement adapter `Prepare` methods.
  - Add stream-control/backpressure tests on execution flows.
  - Add explicit batch/multi-result/generated-key API coverage.
