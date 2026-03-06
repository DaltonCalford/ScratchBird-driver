# DOTNET-103 Verification Notes (2026-03-06T04:36:00Z)

## Status
Verification complete. Isolation/deadlock fault-injection matrix coverage is implemented with multi-round runtime controls and deterministic summary reporting.

## What changed
- Extended `SoakAndFaultInjectionTests.IsolationAndDeadlockFaultInjectionMatrixHarness` with:
  - configurable rounds (`SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS`)
  - round-based matrix execution across `ReadCommitted` and `Serializable`
  - explicit outcome accounting (`committed` vs `contended`)
  - parseable runtime summary output.
- Hardened verifier script (`verification_dotnet_fault_matrix.sh`) with:
  - minimum-round guard (`SCRATCHBIRD_DOTNET_FAULT_MATRIX_MIN_ROUNDS`)
  - optional short-run bypass (`DOTNET_HARNESS_ALLOW_SHORT_RUNTIME=1`)
  - required runtime summary-line validation.

## Evidence
- `tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/SoakAndFaultInjectionTests.cs`
- `artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh`
- `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`
- `artifacts/enterprise-readiness/run_dotnet_soak_suite.sh`

## Latest execution result
- Deterministic verifier pass captured in `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`.
- .NET soak/fault suite pass captured via:
  - `DOTNET_HARNESS_MODE=deterministic bash artifacts/enterprise-readiness/run_dotnet_soak_suite.sh`

## Remaining work
None blocking DOTNET-103. Runtime endpoint matrix execution for additional managed/listener profiles is operational evidence work and is supported by the updated JDBC-203 profile-aware gate.

## Verification command

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```

Runtime matrix mode:

```bash
DOTNET_HARNESS_MODE=runtime \
SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
SCRATCHBIRD_DOTNET_FAULT_MATRIX_ROUNDS=24 \
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```
