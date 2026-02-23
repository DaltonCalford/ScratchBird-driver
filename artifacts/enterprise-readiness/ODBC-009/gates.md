# ODBC-009: Enterprise ODBC Release Gate

This gate is the minimum artifact set required before ODBC release unblock.

## Scope
- ODBC core in-tree tests
- ODBC capability signaling and metadata surfaces already covered by ODBC-001 through ODBC-008
- BI-style conformance checks and stability/sizing checks
- Runtime behavior stability checks for representative query paths

## Pass Criteria

- `scratchbird_odbc_tests` runs and exits success.
- No regression from ODBC-001 through ODBC-008 acceptance matrices (feature signaling, metadata, descriptors, cursor paths, bulk/Lob, and browse behaviors).
- BI-style query path completes for at least:
  - `table`/`columns` style metadata discovery
  - `procedures`/`procedureColumns` metadata traversal
  - a basic native protocol execution path
- No critical warnings or hard-fail state from memory/perf sanity checks.

## Fail Criteria

- Any ODBC suite failure or crash.
- Missing expected metadata contract output from a known accepted path.
- Test execution timeouts or unrecoverable runtime instability.
- Missing or stale log artifacts that prevent audit reproducibility.

## Reproducibility Controls

- Execution logs are written to:
  - `artifacts/enterprise-readiness/ODBC-009/latest_verification.log`
  - `artifacts/enterprise-readiness/ODBC-009/run_odbc_enterprise_gate.log`
- A unique timestamped log must be retained for each gate run and kept with the latest link.

## Rollback Conditions

- If gate fails: keep ticket in `in_progress`, add failing log to notes, and
  open follow-up tasks under ODBC workstreams or platform runtime readiness.
