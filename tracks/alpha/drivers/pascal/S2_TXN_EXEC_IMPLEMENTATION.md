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
- Implemented adapter `Prepare` behavior in:
  - `src/ScratchBird.FireDAC.pas`
  - `src/ScratchBird.IBX.pas`
  - `src/ScratchBird.SQLdb.pas`
  - `src/ScratchBird.Zeos.pas`
  so `Prepare` now normalizes/caches SQL and parameter ordering for reuse by `Open`/`ExecSQL`.
- Added adapter advanced transaction forwarding surface (`StartTransactionEx`) in:
  - `src/ScratchBird.FireDAC.pas`
  - `src/ScratchBird.IBX.pas`
  - `src/ScratchBird.SQLdb.pas`
  - `src/ScratchBird.Zeos.pas`
  so adapter callers can access `BeginTransactionEx` options parity without dropping to the raw client API.
- Added `tests/AdapterTransactionOptionsTests.pas` for disconnected guard parity on adapter `StartTransactionEx` across all four adapter surfaces.
- Added deterministic transaction-state transition suite:
  - `tests/TxnStateTransitionsTests.pas`
  - validates wire-`READY` lifecycle transitions for begin/savepoint/release/rollback-to/commit and begin/rollback flows.
  - validates post-commit/post-rollback active-transaction guard behavior via savepoint/release calls.
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

5. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_txn_opts_build -FE/tmp/sb_pascal_txn_opts_bin ./tracks/alpha/drivers/pascal/tests/AdapterTransactionOptionsTests.pas`
- Result: PASS (compile succeeded).

6. `/tmp/sb_pascal_txn_opts_bin/AdapterTransactionOptionsTests`
- Result: PASS (`AdapterTransactionOptionsTests: OK`).

7. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_txn_state_build -FE/tmp/sb_pascal_txn_state_bin ./tracks/alpha/drivers/pascal/tests/TxnStateTransitionsTests.pas`
- Result: PASS (compile succeeded).

8. `/tmp/sb_pascal_txn_state_bin/TxnStateTransitionsTests`
- Result: PASS (`TxnStateTransitionsTests: OK`).

## TXN Status

- Recommendation: `PARTIAL`

Rationale:
- Deterministic lane-local TXN guardrails now exist and are covered by dedicated tests (disconnected begin, no-active-txn commit/rollback behavior, savepoint active-txn and name validation, txn payload encoding checks).
- Deterministic transaction state transitions are now asserted end-to-end against wire `READY` transaction ids for begin/savepoint/release/rollback-to/commit and begin/rollback paths.
- Adapter surfaces now expose advanced transaction options via `StartTransactionEx` forwarding, with deterministic lane-local guard tests.
- Remaining gap preventing `MET`: no live server transaction lifecycle integration coverage for begin/commit/rollback/savepoint.

## EXEC Status

- Recommendation: `PARTIAL`

Rationale:
- Deterministic lane-local execution parity improved with blank SQL validation, cast-safe named-parameter normalization, adapter `Prepare` normalization/cache behavior, stream-control/backpressure assertions, and generated-key metadata exposure.
- Remaining gaps prevent `MET`: no live execution integration depth yet for advanced execution paths against a running server.

## Remaining Concrete Gaps

- TXN:
  - Add live integration tests for full transaction lifecycle against a running ScratchBird endpoint.
- EXEC:
  - Add live integration assertions for advanced execution APIs (batch/multi-result/stream-control) against a running ScratchBird endpoint.
