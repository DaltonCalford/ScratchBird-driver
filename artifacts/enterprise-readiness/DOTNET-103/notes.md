# DOTNET-103 Verification Notes (2026-02-23T03:49:56Z)

## Status
In progress (concurrent writer/read contention coverage added; strict lock-downgrade semantics still pending external fault injection).

## What changed
- Added table-backed savepoint lifecycle verification using nested savepoint rollback (`SavepointNestedRollbackAndReadCommittedIsolation`).
- Proved rollback-to-savepoint leaves earlier changes visible while earlier writes remain in the same transaction.
- Added transient handle recovery path coverage for stale/closed protocol clients in open transaction flows.
- Kept existing nested savepoint API coverage (`Save`, `Rollback(name)`, `Release`) in `SavepointRollbackAndRelease`.
- Transaction actions continue to use the resilient connected client path so reconnect/health check applies to commit/rollback/saves.
- Added concurrent writer/read session test (`ConcurrentWritersAndReaderSessionMaintainIsolation`) covering:
  - concurrent transaction overlap under same row contention conditions,
  - cancellation/timeout handling in second writer path,
  - post-transaction read-after-write session recovery.

## Evidence
- `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_pool_and_tx_20260223T040500Z.log`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_concurrency_20260223T034956Z.log`

Latest verification run:

- `2026-02-23T03:49:56Z` stored at `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_concurrency_20260223T034956Z.log`

## Remaining gaps
- Mixed read/write session and concurrent writer overlap now covered.
- Lock-contention assertions and strict isolation matrix still pending explicit deadlock/serialization fault injection.
