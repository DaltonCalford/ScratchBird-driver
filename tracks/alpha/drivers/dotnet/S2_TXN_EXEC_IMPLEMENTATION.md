# S2 TXN/EXEC Implementation (DLB-DOTNET-003)

Scope: `tracks/alpha/drivers/dotnet` lane only.

## Changes

- Added active transaction tracking on `ScratchBirdConnection` and enforced one active local transaction per connection.
- Cleared tracked transaction state on connection close/reconnect paths to avoid stale transaction reuse.
- Updated `ScratchBirdTransaction` to:
  - expose internal state (`IsCompleted`, `IsDisposed`) for parity checks;
  - validate active ownership before transaction operations;
  - clear connection transaction tracking on commit/rollback completion.
- Updated `ScratchBirdCommand` execution/prepare guardrails to enforce:
  - non-empty `CommandText`;
  - explicit command transaction when connection has an active transaction;
  - transaction belongs to command connection;
  - transaction is active/not disposed/not completed;
  - non-negative `CommandTimeout`.
- Added focused unit tests in `TransactionExecutionParityTests` for TXN/EXEC guardrails.
- Updated TXN/EXEC rows in `BASELINE_REQUIREMENT_MAPPING.md` with new evidence anchors.

## Tests Run

- `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~TransactionExecutionParityTests"`: **PASS** (7 passed, 0 failed, 0 skipped)

## TXN Status

- Recommendation: **PARTIAL**
- Reason: transaction lifecycle and active-ownership guardrails are now explicit and tested, but isolation mapping still intentionally falls back to read committed for unsupported values.

## EXEC Status

- Recommendation: **PARTIAL**
- Reason: execution guardrails for transaction binding and command-state validation are now explicit and tested, but surface area remains intentionally limited (`CommandType.Text`, input-parameter scope).

## Remaining Gaps

- Unsupported isolation levels are mapped to read committed instead of raising/fully emulating per-level semantics.
- Execution surface does not yet expand beyond `CommandType.Text` and current input parameter model.
