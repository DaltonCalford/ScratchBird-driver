# ODBC-009: Enterprise ODBC Release Gate

This gate is the minimum artifact set required before ODBC release unblock.

## Scope
- ODBC core in-tree tests
- ODBC capability signaling and metadata surfaces already covered by ODBC-001 through ODBC-008
- BI-style conformance checks and stability/sizing checks
- Runtime behavior stability checks for representative query paths

## Pass Criteria

- `scratchbird_odbc_tests` runs and exits success.
- `/usr/bin/time` metrics are captured (`elapsed`, `max_rss_kb`, cpu/user split, context switches) and baseline trend checks pass.
- No regression from ODBC-001 through ODBC-008 acceptance matrices (feature signaling, metadata, descriptors, cursor paths, bulk/Lob, and browse behaviors).
- BI-style query path completes for at least:
  - `table`/`columns` style metadata discovery
  - `procedures`/`procedureColumns` metadata traversal
  - a basic native protocol execution path
- ODBC capability matrix checks pass against expected function/info matrices:
  - `artifacts/enterprise-readiness/ODBC-008/odbc_function_matrix.csv`
  - `artifacts/enterprise-readiness/ODBC-008/odbc_info_matrix.csv`
- If `ODBC_009_BI_SMOKE_CMD` is configured, it completes successfully.
- If `ODBC_009_HOSTED_BI_SMOKE=1`, hosted vendor smoke passes for configured Tableau/Power BI/Excel DSNs.
- No critical warnings or hard-fail state from memory/perf sanity checks.

## Fail Criteria

- Any ODBC suite failure or crash.
- Missing expected metadata contract output from a known accepted path.
- Test execution timeouts or unrecoverable runtime instability.
- Memory/performance baseline regression versus previous sample (`ODBC_009_ELAPSED_REGRESSION_THRESHOLD` / `ODBC_009_MAX_RSS_REGRESSION_THRESHOLD`).
- BI smoke command failure or missing command while `ODBC_009_BI_SMOKE_MANDATORY=1`.
- Capability matrix comparison failure while `ODBC_009_CAPABILITY_MATRIX_MANDATORY=1`.
- Hosted BI-vendor smoke failure while `ODBC_009_HOSTED_BI_SMOKE=1`, or missing enable flag while `ODBC_009_HOSTED_BI_SMOKE_MANDATORY=1`.
- Missing or stale log artifacts that prevent audit reproducibility.

## Reproducibility Controls

- Execution logs are written to:
  - `artifacts/enterprise-readiness/ODBC-009/latest_verification.log`
  - `artifacts/enterprise-readiness/ODBC-009/run_odbc_enterprise_gate.log`
  - `artifacts/enterprise-readiness/ODBC-009/latest_perf_snapshot.json`
  - `artifacts/enterprise-readiness/ODBC-009/perf_baseline.csv`
- A unique timestamped log must be retained for each gate run and kept with the latest link.

## Rollback Conditions

- If gate fails: keep ticket in `in_progress`, add failing log to notes, and
  open follow-up tasks under ODBC workstreams or platform runtime readiness.
