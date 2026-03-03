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
  - non-negative `CommandTimeout`;
  - `CommandType.StoredProcedure` parity with generated callable SQL (`CALL "schema"."routine"($1,...)`).
- Expanded transaction isolation mapping in `ProtocolClient`:
  - `Snapshot` and `Chaos` now map deterministically to wire `SERIALIZABLE` instead of falling through to default.
- Added focused unit tests in `TransactionExecutionParityTests` for TXN/EXEC guardrails.
- Updated TXN/EXEC rows in `BASELINE_REQUIREMENT_MAPPING.md` with new evidence anchors.

## Tests Run

- `dotnet test --filter "FullyQualifiedName!~IntegrationTests"`: **PASS** (48 passed, 0 failed, 0 skipped)

## TXN Status

- Recommendation: **PARTIAL**
- Reason: transaction lifecycle and active-ownership guardrails are explicit/tested and snapshot/chaos now map deterministically, but full live isolation-matrix validation remains pending.

## EXEC Status

- Recommendation: **PARTIAL**
- Reason: execution guardrails and callable `StoredProcedure` command shaping are now explicit/tested, but output-parameter and broader command-surface parity still remain.

## Remaining Gaps

- Isolation-level semantics are still bounded to the wire isolation enum (`read-uncommitted`, `read-committed`, `repeatable-read`, `serializable`) and not yet integration-verified across full server behavior matrix.
- Execution surface still lacks output-parameter and provider-specific command behaviors beyond text/callable input-parameter flows.
