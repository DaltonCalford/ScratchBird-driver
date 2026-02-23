# ODBC-009 Verification Notes

Status: In progress (in-tree gate pass captured; full BI external runbook pending)

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
- `artifacts/enterprise-readiness/ODBC-009/verification_20260223T023045Z.log`
- `artifacts/enterprise-readiness/ODBC-009/latest_verification.log` (41 tests)

Latest verification run:

- `2026-02-23T02:30:45Z` stored at `artifacts/enterprise-readiness/ODBC-009/verification_20260223T023045Z.log`

## Blockers
- BI native/connector-side runbook invocation is stubbed as a local gate step until a hosted BI fixture is integrated in CI.
- This gate currently runs in-tree ODBC unit suite as the minimum enterprise proxy.

## Next Step
- Add CI job wiring for this same gate script and route BI smoke placeholders to an approved harness.
