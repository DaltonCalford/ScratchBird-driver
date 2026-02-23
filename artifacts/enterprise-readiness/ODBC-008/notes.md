# ODBC-008 Verification Notes

Status: Verification attempted (strict capability signal updates applied)

## Evidence
- `cmake -S . -B build -DBUILD_TESTING=ON`
- `cmake --build build --target scratchbird_odbc -j 4`
- `ctest --test-dir build --output-on-failure`

Latest verification run:

- `2026-02-23T01:02:07Z` stored at `artifacts/enterprise-readiness/ODBC-008/verification_2026-02-23T010207Z.log`

## Findings
- `SQLGetFunctions` now reports a clean, supported-function list built from header constants.
- Removed incorrect/overstated IDs and fixed `SQLSetConnectAttr` collision.
- Kept unsupported/unimplemented APIs (for example `SQLGetCursorName`) out of advertised bitmap.

## Blocker
- No ODBC capability matrix executable in this tree:
  - `Could NOT find GTest` during configure.
  - `No tests were found!!!` from ctest.
