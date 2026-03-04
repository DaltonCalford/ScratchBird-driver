# DOTNET-101 Verification Notes (2026-03-04T18:47:12Z)

## Status
In progress. Core async/cancel paths are validated, and a sustained cancellation/release soak harness is now implemented with explicit runtime controls.

## What changed
- Added cancellation token coverage for async reader workflows (`ExecuteReaderAsync` + `ReadAsync`).
- Added regression coverage that a token-cancelled async reader leaves the connection reusable for immediate follow-up query.
- Added pre-cancel token behavior and concurrent cancellation stress across pooled connections.
- Added explicit stream-abort + dispose cleanup for canceled readers.
- Preserved existing command-driven cancellation and command-token cancellation assertions.
- Added long-run soak harness test:
  - `SoakAndFaultInjectionTests.CancellationReleaseSoakHarness`
  - opt-in via `SCRATCHBIRD_DOTNET_SOAK_ENABLE=1`
  - runtime duration control via `SCRATCHBIRD_DOTNET_SOAK_SECONDS` (supports long-lived soak windows).

## Evidence
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_async_cancel_20260223T034232Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_test_20260223T034229Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_test_20260223T034409Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_async_cancel_20260223T033907Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_test_20260223T034038Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_test_20260223T033914Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak_harness_20260304T183302Z.log`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh`

## Latest execution result
- 23 total tests, 23 passed in `verification_dotnet_test_20260223T034409Z.log` (integration tests remain environment-gated by `SCRATCHBIRD_DOTNET_URL` and `SCRATCHBIRD_DOTNET_CANCEL_SQL` as applicable).
- 3 targeted cancellation stress tests passed in `verification_dotnet_async_cancel_20260223T034232Z.log`.
- Soak harness contract test compiles/runs in deterministic mode in `verification_dotnet_soak_harness_20260304T183302Z.log`.
- Runtime-mode soak harness executed successfully (20s window) and captured in `artifacts/enterprise-readiness/DOTNET-101/latest_verification.log`:
  - iterations: 8
  - verifyReads: 8
  - transientOrCancelled: 0

## Remaining work
- Execute long-duration soak run with `SCRATCHBIRD_DOTNET_SOAK_ENABLE=1` and production-like runtime DSN/cancel SQL, then capture extended leak/counter telemetry.

## Verification command

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh
```

Runtime soak mode:

```bash
DOTNET_HARNESS_MODE=runtime \
SCRATCHBIRD_DOTNET_URL='scratchbird://...'
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh
```
