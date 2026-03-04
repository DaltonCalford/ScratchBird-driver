# DOTNET-103 Verification Notes (2026-03-04T18:48:06Z)

## Status
In progress (concurrent writer/read contention coverage is in place, and an explicit isolation/deadlock fault-injection matrix harness is now implemented with runtime controls).

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
- Added isolation/deadlock fault matrix harness:
  - `SoakAndFaultInjectionTests.IsolationAndDeadlockFaultInjectionMatrixHarness`
  - opt-in via `SCRATCHBIRD_DOTNET_FAULT_MATRIX_ENABLE=1`
  - exercises `ReadCommitted` and `Serializable` contention paths with cancel/timeout fault injection.

## Evidence
- `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_pool_and_tx_20260223T040500Z.log`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_concurrency_20260223T034956Z.log`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix_harness_20260304T183302Z.log`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh`

Latest verification run:

- `2026-03-04T18:48:06Z` runtime-mode fault-matrix run captured in `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`.

## Remaining gaps
- Mixed read/write session and concurrent writer overlap now covered.
- Execute runtime-backed fault matrix with `SCRATCHBIRD_DOTNET_FAULT_MATRIX_ENABLE=1` against managed/listener endpoints to capture deadlock/serialization telemetry artifacts.

## Verification command

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```

Runtime fault-matrix mode:

```bash
DOTNET_HARNESS_MODE=runtime \
SCRATCHBIRD_DOTNET_URL='scratchbird://...'
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```
