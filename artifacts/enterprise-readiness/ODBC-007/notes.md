# ODBC-007 Verification Notes

Status: In progress (read-side chunked `SQLGetData` implemented; write side still pending).

## Evidence
- Added chunked `SQLGetData` state machine in `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`:
  - Stateful per-column continuation using `get_data_stream_`.
  - Proper truncation handling for `SQL_C_CHAR`, `SQL_C_DEFAULT`, and `SQL_C_BINARY`.
  - Row/result-set transitions (`fetch`, `fetchScroll`, `setPos`, `applyResultSet`, `resetResults`) clear active stream state.
- Added regression coverage in `tracks/alpha/drivers/odbc/tests/test_odbc_lob_streaming.cpp`:
  - `TextGetDataStreamsInChunksAndFinishes`
  - `BinaryGetDataStreamsRawBytes`
  - `StreamStateResetsOnPositionChange`
- Included new test file in `tracks/alpha/drivers/odbc/CMakeLists.txt`.
- Build and test command artifacts captured:
  - `artifacts/enterprise-readiness/ODBC-007/cmake_configure.log`
  - `artifacts/enterprise-readiness/ODBC-007/build_scratchbird_odbc.log`
  - `artifacts/enterprise-readiness/ODBC-007/verification_tests.log`

## Current Blocker
- GoogleTest is not present in this tree (`Could NOT find GTest`), so runtime verification for new test cases is not executable in-tree yet.

## Files touched
- `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`
- `tracks/alpha/drivers/odbc/include/scratchbird/odbc/odbc_handles.h`
- `tracks/alpha/drivers/odbc/tests/test_odbc_lob_streaming.cpp`
- `tracks/alpha/drivers/odbc/CMakeLists.txt`
- `artifacts/enterprise-readiness/ODBC-007/*`

## Next step
- Add `SQLPutData` + parameter stream write lifecycle and execute `ctest --test-dir build/odbc_local` once GTest is available.
