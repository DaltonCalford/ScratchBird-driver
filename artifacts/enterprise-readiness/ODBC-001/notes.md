# ODBC-001 Verification Notes

Status: Verification complete (in-tree ODBC unit suite)

## Evidence
- `cmake -S . -B build -DBUILD_TESTING=ON`
- `cmake --build build --target scratchbird_odbc -j 4`
- `cmake --build build --target scratchbird_odbc_tests -j 4`
- `build/tracks/alpha/drivers/odbc/scratchbird_odbc_tests` (43 tests, all passed)

Latest verification run:

- `2026-02-23T05:43:37Z` summarized in `artifacts/enterprise-readiness/ODBC-001/verification_tests.log`

## Findings
- `SQLSetEnvAttr(SQL_NULL_HENV, SQL_ATTR_CONNECTION_POOLING, ...)` now applies the requested pooling
  default to subsequent environment allocations via shared driver state.
- Added regression test `OdbcCapabilityBrowseTest.NullEnvConnectionPoolingDefaultsPropagateToNewEnvironments`
  in `tracks/alpha/drivers/odbc/tests/test_odbc_capabilities_browse.cpp` covering:
  - `SQL_NULL_HENV` set path
  - default propagation to a new environment
  - `SQLGetEnvAttr` visibility of that value
- ODBC-001 in-tree suite currently runs 43 tests (including regression).
- `SQLGetFunctions` map updated to explicit API IDs from installed ODBC headers:
  - Added ODBC 3.x handles/descriptors/cursor/metadata/metadata helper function IDs.
  - Removed prior duplicated/incorrect `SQLSetConnectAttr` mapping (ID collision with `SQLParamData`).
  - Removed false-positive entries for unsupported `SQLGetCursorName`.
- `SQLGetFunctions` now treats both `SQL_API_ALL_FUNCTIONS` and `SQL_API_ODBC3_ALL_FUNCTIONS` as supported bitmap queries in this driver.

## Blocker
- No current blockers.
