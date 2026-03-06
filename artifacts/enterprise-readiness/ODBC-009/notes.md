# ODBC-009 Verification Notes

Status: Verification complete (in-tree ODBC gate + mandatory BI smoke subset command executed in CI)

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
- `artifacts/enterprise-readiness/ODBC-009/verification_20260223T054922Z.log`
- `artifacts/enterprise-readiness/ODBC-009/odbc_bi_smoke.sh`
- `artifacts/enterprise-readiness/ODBC-009/latest_verification.log` (45 tests)
- `artifacts/enterprise-readiness/ODBC-009/perf_baseline.csv`
- `artifacts/enterprise-readiness/ODBC-009/latest_perf_snapshot.json`

Latest verification run:

- `2026-02-23T05:49:22Z` stored at `artifacts/enterprise-readiness/ODBC-009/verification_20260223T054922Z.log`

## Blockers
- BI connector-style smoke command now runs an in-tree ODBC smoke subset (`OdbcSmokeTest`, `OdbcCapabilityBrowseTest`, `OdbcCatalogTest`) during the gate.
- This gate now executes the minimum reproducible enterprise proxy:
  - in-tree ODBC unit suite
  - documented gate checklist and run artifacts
- Memory/perf baseline checks are now persisted as CSV + JSON snapshot for trend tracking.
- BI smoke command support:
  - Default command: `artifacts/enterprise-readiness/ODBC-009/odbc_bi_smoke.sh` (in-tree deterministic smoke subset).
  - Configure `ODBC_009_BI_SMOKE_CMD` for alternate BI smoke implementations.
  - Set `ODBC_009_BI_SMOKE_MANDATORY=1` to hard-fail when smoke hook is unavailable.
- Added capability-matrix hardening hook in gate path:
  - `artifacts/enterprise-readiness/ODBC-008/run_capability_matrix_check.sh`
  - expected matrices: `odbc_function_matrix.csv` + `odbc_info_matrix.csv`
- Added optional hosted BI-vendor hardening hook:
  - set `ODBC_009_HOSTED_BI_SMOKE=1` to run `odbc_bi_vendor_smoke.sh`
  - runtime envs: `SCRATCHBIRD_ODBC_TABLEAU_CONNSTR`, `SCRATCHBIRD_ODBC_POWERBI_CONNSTR`, `SCRATCHBIRD_ODBC_EXCEL_CONNSTR`

## Next Step
- CI job wiring is now in place on the Linux ODBC workflow path.
- Hosted BI-vendor smoke remains opt-in until vendor fixtures are provisioned in CI.
