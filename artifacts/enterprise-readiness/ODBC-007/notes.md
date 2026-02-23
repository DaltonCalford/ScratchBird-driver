# ODBC-007 Verification Notes

Status: In progress (read-side and write-side streaming implemented; verification blocked by missing GoogleTest harness in-tree).

## Evidence
- Added streaming implementation in `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`:
  - Stateful SQLDataAtExec stream lifecycle using `put_data_stream_`.
  - Support for `SQLParamData`/`SQLPutData` token/sequence coordination.
  - Chunked write path via `putData` with support for `SQL_DATA_AT_EXEC` and `SQL_LEN_DATA_AT_EXEC` indicators.
  - Truncation handling and stream completion transitions.
  - Read/write safety cleanup in `fetch`, `fetchScroll`, `setPos`, `applyResultSet`, and `resetResults`.
- Added SQLGetFunctions advertising and capability assertions in `tracks/alpha/drivers/odbc/tests/test_odbc_capabilities_browse.cpp` for:
  - `SQLParamData`
  - `SQLPutData`
- Added/extended regression tests in `tracks/alpha/drivers/odbc/tests/test_odbc_lob_streaming.cpp`:
  - `TextGetDataStreamsInChunksAndFinishes`
  - `BinaryGetDataStreamsRawBytes`
  - `StreamStateResetsOnPositionChange`
  - `SQLPutDataUnknownLengthStreamsTextAndExecutes`
  - `SQLPutDataKnownLengthBinaryAutoCompletes`
- Added SQLDataAtExec API declarations and symbol wiring:
  - `tracks/alpha/drivers/odbc/include/scratchbird/odbc/odbc_driver.h`
  - `tracks/alpha/drivers/odbc/src/odbc_driver.cpp`
  - `tracks/alpha/drivers/odbc/include/scratchbird/odbc/odbc_handles.h`
- Build and test command artifacts captured:
  - `artifacts/enterprise-readiness/ODBC-007/cmake_configure.log`
  - `artifacts/enterprise-readiness/ODBC-007/build_scratchbird_odbc.log`
  - `artifacts/enterprise-readiness/ODBC-007/verification_tests.log`

## Current Blocker
- GoogleTest is not present in this tree (`Could NOT find GTest`), so runtime execution for new test cases is not yet possible in-tree.
- `ctest --test-dir build/odbc_local` currently reports no tests discovered.

## Files touched
- `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`
- `tracks/alpha/drivers/odbc/include/scratchbird/odbc/odbc_handles.h`
- `tracks/alpha/drivers/odbc/include/scratchbird/odbc/odbc_driver.h`
- `tracks/alpha/drivers/odbc/src/odbc_driver.cpp`
- `tracks/alpha/drivers/odbc/tests/test_odbc_capabilities_browse.cpp`
- `tracks/alpha/drivers/odbc/tests/test_odbc_lob_streaming.cpp`
- `artifacts/enterprise-readiness/ODBC-007/*`

## Next step
- Add GoogleTest dependency, run `ctest --test-dir build/odbc_local`, and confirm streaming tests pass:
  - `TextGetDataStreamsInChunksAndFinishes`
  - `BinaryGetDataStreamsRawBytes`
  - `StreamStateResetsOnPositionChange`
  - `SQLPutDataUnknownLengthStreamsTextAndExecutes`
  - `SQLPutDataKnownLengthBinaryAutoCompletes`
