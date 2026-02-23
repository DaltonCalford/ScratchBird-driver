# DOTNET-102 Verification Notes (2026-02-23T03:12:21Z)

## Status
In progress (pool implementation repaired and compilation/test baseline re-verified on 2026-02-23T03:19:08Z).

## What changed
- Added connection pooling controls and lease lifecycle handling via `ProtocolClientPool`.
- Added retry/backoff path on open and reconnect through `ScratchBirdConnection` for unhealthy connections.
- Added automatic reconnect checks at command/transaction/reader entry points.
- Added integration assertion for protocol client reuse across pooled opens (`ConnectionPoolingReusesProtocolClient`).
- Rebuilt `ProtocolClientPool` with explicit tracked/untracked lease handling, explicit pool-key stability and connection lifetime enforcement.
- Added slot-based borrow/return guardrails with back-pressure and fallback-only-untracked connections when pool is saturated.

## Evidence
- `artifacts/enterprise-readiness/DOTNET-102/latest_verification.log`
- `artifacts/enterprise-readiness/DOTNET-102/recovery_verification_20260223T031908Z.log`

## Next verification items
- Add soak/reconnect/failover tests for transient failures and saturation behavior.
- Add leak/corruption assertions for lease return and stale handle handling.
