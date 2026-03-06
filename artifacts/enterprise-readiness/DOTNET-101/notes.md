# DOTNET-101 Verification Notes (2026-03-06T04:36:00Z)

## Status
Verification complete. Sustained async cancellation/release soak coverage is implemented with explicit runtime-duration guards, threshold assertions, and telemetry-rich summaries.

## What changed
- Added sustained-run controls for `SoakAndFaultInjectionTests.CancellationReleaseSoakHarness`:
  - `SCRATCHBIRD_DOTNET_SOAK_SECONDS`
  - `SCRATCHBIRD_DOTNET_SOAK_MIN_ITERATIONS`
  - `SCRATCHBIRD_DOTNET_SOAK_MIN_VERIFY_READS`
- Added stronger pool lifecycle assertions in the harness:
  - idle pool drain (`ActiveCount == 0`)
  - monotonic borrow/return counter checks
- Added parseable soak summary output with counters and thresholds.
- Hardened verifier script (`verification_dotnet_soak.sh`) with:
  - runtime minimum-duration guard (`SCRATCHBIRD_DOTNET_SOAK_MIN_SECONDS`)
  - optional short-run bypass (`DOTNET_HARNESS_ALLOW_SHORT_RUNTIME=1`)
  - required runtime summary-line validation.

## Evidence
- `tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/SoakAndFaultInjectionTests.cs`
- `artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh`
- `artifacts/enterprise-readiness/DOTNET-101/latest_verification.log`
- `artifacts/enterprise-readiness/run_dotnet_soak_suite.sh`

## Latest execution result
- Deterministic verifier pass captured in `artifacts/enterprise-readiness/DOTNET-101/latest_verification.log`.
- .NET soak/fault suite pass captured via:
  - `DOTNET_HARNESS_MODE=deterministic bash artifacts/enterprise-readiness/run_dotnet_soak_suite.sh`

## Remaining work
None blocking DOTNET-101. Extended-duration production soak windows remain an operational runtime-evidence activity, not a code gap.

## Verification command

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh
```

Runtime sustained mode:

```bash
DOTNET_HARNESS_MODE=runtime \
SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
SCRATCHBIRD_DOTNET_SOAK_SECONDS=1800 \
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh
```
