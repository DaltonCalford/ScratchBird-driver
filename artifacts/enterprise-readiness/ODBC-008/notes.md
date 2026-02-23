# ODBC-008 Verification Notes

Status: Verification complete (in-tree ODBC unit suite)

## Evidence
- `cmake -S . -B build -DBUILD_TESTING=ON`
- `cmake --build build --target scratchbird_odbc -j 4`
- `ctest --test-dir build --output-on-failure`
- `build_odbc_test/tracks/alpha/drivers/odbc/scratchbird_odbc_tests`

Latest verification run:

- `2026-02-23T02:43:00Z` stored at `artifacts/enterprise-readiness/ODBC-008/verification_20260223T024300Z.log`

## Findings
- `SQLGetFunctions` now reports a clean, supported-function list built from header constants.
- Removed incorrect/overstated IDs and fixed `SQLSetConnectAttr` collision.
- Kept unsupported/unimplemented APIs (for example `SQLGetCursorName`) out of advertised bitmap.
- Added explicit handling so `SQL_API_ALL_FUNCTIONS` now returns the same ODBC 3.x function bitmap as `SQL_API_ODBC3_ALL_FUNCTIONS`.

## Blocker
- No blockers.
