# DOTNET-102 Verification Notes (2026-03-04T18:47:44Z)

## Status
In progress (pool lifecycle metrics, stale-handle recovery, idle eviction, and saturation-path counters are covered; failover-saturation soak harness is now implemented with runtime controls).

## What changed
- Added connection pooling controls and lease lifecycle handling via `ProtocolClientPool`.
- Added retry/backoff path on open and reconnect through `ScratchBirdConnection` for unhealthy connections.
- Added automatic reconnect checks at command/transaction/reader entry points.
- Added integration assertion for protocol client reuse across pooled opens (`ConnectionPoolingReusesProtocolClient`).
- Extended pool lifecycle validation (`PoolConnectionLifetimeEvictsIdleClientsAndReleasesNewBorrow`):
  - proves expired idle clients are evicted when connection lifetime elapses
  - verifies pool stats capture eviction and borrow/return counters
- Added stale-handle recovery coverage (`RecoverFromStaleClientHandleAfterDisconnect`):
  - closes an active client handle and verifies command execution reacquires a healthy handle
- Rebuilt `ProtocolClientPool` with explicit tracked/untracked lease handling, explicit pool-key stability and connection lifetime enforcement.
- Added slot-based borrow/return guardrails with back-pressure and fallback-only-untracked connections when pool is saturated.
- Added pool counters in `ProtocolClientPool.PoolStats` (`BorrowAttempts`, `Borrowed`, `Returned`, `Rejected`, `Evicted`).
- Added saturation stress coverage (`PooledConnectionSaturationCreatesFallbackClients`) that holds multiple pooled opens under timeout pressure, proving fallback paths activate when pool slots are exhausted.
- Added failover/reconnect soak harness test:
  - `SoakAndFaultInjectionTests.FailoverSaturationRecoveryHarness`
  - opt-in via `SCRATCHBIRD_DOTNET_FAILOVER_SOAK_ENABLE=1`
  - duration/worker controls via `SCRATCHBIRD_DOTNET_FAILOVER_SOAK_SECONDS` and `SCRATCHBIRD_DOTNET_FAILOVER_WORKERS`.

## Evidence
- `artifacts/enterprise-readiness/DOTNET-102/latest_verification.log`
- `artifacts/enterprise-readiness/DOTNET-102/recovery_verification_20260223T031908Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_reuse_20260223T034344Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_and_tx_20260223T040500Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_saturation_20260223T034956Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_harness_20260304T183302Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh`

Latest verification run:

- `2026-03-04T18:47:44Z` runtime-mode run captured in `artifacts/enterprise-readiness/DOTNET-102/latest_verification.log` with:
  - seconds: 20
  - workers: 4
  - success: 205
  - transient: 0
  - borrowAttempts: 236
  - rejected: 25

## Next verification items
- Execute sustained runtime failover soak with `SCRATCHBIRD_DOTNET_FAILOVER_SOAK_ENABLE=1` to gather bounded retry/recovery telemetry under real endpoint faults.
- Continue queue-pressure correlation through failover/fault-injection scenarios.
- Correlate saturation counters with command timeout/restart behavior under real fault injection.

## Verification command

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh
```

Runtime failover mode:

```bash
DOTNET_HARNESS_MODE=runtime \
SCRATCHBIRD_DOTNET_URL='scratchbird://...'
bash artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh
```
