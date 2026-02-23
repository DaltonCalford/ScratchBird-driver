# ODBC-009 Verification Notes

Status: Verification complete (in-tree ODBC gate executed; BI smoke command path wired, external BI fixture still pending)

## Objective
Operationalize the enterprise ODBC release gate for BI and conformance readiness with reproducible artifacts.

## Command Checklist
- `cmake -S tracks/alpha/drivers/odbc -B tracks/alpha/drivers/odbc/build_odbc_gate -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON`
- `cmake --build tracks/alpha/drivers/odbc/build_odbc_gate --target scratchbird_odbc_tests scratchbird_odbc -j 4`
- `./artifacts/enterprise-readiness/ODBC-009/run_odbc_enterprise_gate.sh`

## Evidence
- `artifacts/enterprise-readiness/ODBC-009/gates.md`
- `artifacts/enterprise-readiness/ODBC-009/run_odbc_enterprise_gate.sh`
- `artifacts/enterprise-readiness/ODBC-009/run_odbc_enterprise_gate.log`
- `artifacts/enterprise-readiness/ODBC-009/verification_20260223T024254Z.log`
- `artifacts/enterprise-readiness/ODBC-009/latest_verification.log` (41 tests)
- `artifacts/enterprise-readiness/ODBC-009/perf_baseline.csv`
- `artifacts/enterprise-readiness/ODBC-009/latest_perf_snapshot.json`

Latest verification run:

- `2026-02-23T02:42:54Z` stored at `artifacts/enterprise-readiness/ODBC-009/verification_20260223T024254Z.log`

## Blockers
- BI native/connector-side runbook invocation remains placeholder-only until a hosted BI fixture is integrated in CI.
- This gate now executes the minimum reproducible enterprise proxy:
  - in-tree ODBC unit suite
  - documented gate checklist and run artifacts
- Memory/perf baseline checks are now persisted as CSV + JSON snapshot for trend tracking.
- BI smoke command support:
  - Configure `ODBC_009_BI_SMOKE_CMD` for optional BI connector smoke execution.
  - Set `ODBC_009_BI_SMOKE_MANDATORY=1` to hard-fail when smoke hook is missing.

## Next Step
- CI job wiring is now in place on the Linux ODBC workflow path.
- Replace the placeholder BI smoke path with hosted BI tooling and set mandatory mode for release hardening.
