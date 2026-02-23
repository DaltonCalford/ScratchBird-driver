# ODBC-001 Verification Notes

Status: Verification attempted (code/signaling fixes applied)

## Evidence
- `cmake -S . -B build -DBUILD_TESTING=ON`
- `cmake --build build --target scratchbird_odbc -j 4`
- `ctest --test-dir build --output-on-failure`

Latest verification run:

- `2026-02-23T01:02:07Z` stored at `artifacts/enterprise-readiness/ODBC-001/verification_2026-02-23T010207Z.log`

## Findings
- `SQLGetFunctions` map updated to explicit API IDs from installed ODBC headers:
  - Added ODBC 3.x handles/descriptors/cursor/metadata/metadata helper function IDs.
  - Removed prior duplicated/incorrect `SQLSetConnectAttr` mapping (ID collision with `SQLParamData`).
  - Removed false-positive entries for unsupported `SQLGetCursorName`.
- Existing BI smoke harness remains unavailable in-repo due missing GoogleTest + no dedicated harness wiring.

## Blocker
- BI smoke matrix and in-tree ODBC functional acceptance harness are still unavailable in this tree:
  - `Could NOT find GTest` during configure.
  - `No tests were found!!!` from ctest.
