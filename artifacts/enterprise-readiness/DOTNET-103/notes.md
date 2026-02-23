# DOTNET-103 Verification Notes (2026-02-23T03:12:21Z)

## Status
In progress.

## What changed
- Added explicit isolation-aware transaction begin using `IsolationLevel` mapping.
- Added savepoint API coverage (`Save`, `Rollback(name)`, `Release`) and integration coverage of `SavepointRollbackAndRelease`.
- Transaction actions now use the resilient connected client path so reconnect/health check applies to commit/rollback/saves.

## Evidence
- `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`

## Remaining gaps
- No concurrent writer matrix yet.
- No mixed read/write session coverage under contention.
- No rollback-to-savepoint/lock contention assertions.
