# ODBC-008 Verification Notes

Status: Verification complete (in-tree ODBC unit suite)

## Evidence
- `cmake -S . -B build -DBUILD_TESTING=ON`
- `cmake --build build --target scratchbird_odbc -j 4`
- `ctest --test-dir build --output-on-failure`
- `build_odbc_test/tracks/alpha/drivers/odbc/scratchbird_odbc_tests`

Latest verification run:

- `2026-02-23T03:02:00Z` stored at `artifacts/enterprise-readiness/ODBC-008/verification_20260223T030200Z.log`

## Findings
- `SQLGetFunctions` now reports a clean, supported-function list built from header constants.
- Removed incorrect/overstated IDs and fixed `SQLSetConnectAttr` collision.
- Kept unsupported/unimplemented APIs (for example `SQLGetCursorName`) out of advertised bitmap.
- Added explicit handling so `SQL_API_ALL_FUNCTIONS` now returns the same ODBC 3.x function bitmap as `SQL_API_ODBC3_ALL_FUNCTIONS`.
- Added `GetFunctionsAdvertisesOnlyImplementedFunctions` coverage that enumerates and validates the function bitmap for exact parity.
- Captured an exported function matrix artifact in `artifacts/enterprise-readiness/ODBC-008/odbc_function_matrix.csv` when enabled via `ODBC_008_CAPABILITY_MATRIX_PATH`.
- Added driver-entry vs handle-getter parity coverage:
  - `DriverEntryGetFunctionsMatchesConnectionGetter`
  - `DriverEntryGetInfoMatchesConnectionGetter`
- Added matrix-comparison coverage and automation:
  - expected function matrix comparison via `ODBC_008_EXPECTED_FUNCTION_MATRIX_PATH`
  - expected info matrix comparison via `ODBC_008_EXPECTED_INFO_MATRIX_PATH`
  - scripted gate helper `artifacts/enterprise-readiness/ODBC-008/run_capability_matrix_check.sh`

## Blocker
- No blockers.
