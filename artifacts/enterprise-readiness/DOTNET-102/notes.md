# DOTNET-102 Verification Notes (2026-02-23T03:49:56Z)

## Status
In progress (pool lifecycle metrics, stale-handle recovery, idle eviction, and saturation-path counters now covered by 2026-02-23T03:49:56Z run).

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

## Evidence
- `artifacts/enterprise-readiness/DOTNET-102/latest_verification.log`
- `artifacts/enterprise-readiness/DOTNET-102/recovery_verification_20260223T031908Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_reuse_20260223T034344Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_and_tx_20260223T040500Z.log`
- `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_saturation_20260223T034956Z.log`

Latest verification run:

- `2026-02-23T03:49:56Z` stored at `artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_pool_saturation_20260223T034956Z.log`

## Next verification items
- Add pooled failover soak with sustained saturation and bounded retry/recovery counters.
- Continue queue-pressure correlation through failover/fault-injection scenarios.
- Correlate saturation counters with command timeout/restart behavior under real fault injection.
