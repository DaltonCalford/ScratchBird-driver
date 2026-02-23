# ODBC-006 Verification Notes

Status: Verification complete (in-tree ODBC unit suite).

## Evidence
- Implemented row-aware bulk parameter materialization in `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`.
- Added `OdbcStatement::buildParameterData(std::vector<ParameterLiteral>&, SQLULEN)` and routed `execute` through it for row 0.
- Added `SQLBulkOperations` path that loops through rowset, executes each bound row, and writes:
  - `SQL_PARAM_SUCCESS` / `SQL_PARAM_ERROR` / `SQL_PARAM_SUCCESS_WITH_INFO`
  - `params_processed_ptr_` and `rows_fetched_ptr_`
- Added bulk operation guard to accept:
  - `SQL_ADD`
  - `SQL_UPDATE_BY_BOOKMARK`
  - `SQL_DELETE_BY_BOOKMARK`
  (these currently execute the prepared statement per row through the shared bulk rowset path).
- Removed duplicated stubbed `bulkOperations` definition.
- Added tests in `tracks/alpha/drivers/odbc/tests/test_odbc_bulk_operations.cpp`:
  - `BulkOperationsExecutesEachRowInOrder`
  - `BulkOperationsUsesBindOffsetInArrayAddressing`
  - `BulkOperationsRejectsUnsupportedOperationCode`
  - `BulkOperationsNoRowsIsNoOp`
  - `BulkOperationsRejectsNonColumnWiseBindingMode`
  - `BulkOperationsSupportsUpdateAndDeleteByBookmarkCodes`
  - `BulkOperationsPartialFailureStopsExecution`
- Wired new bulk test file into `tracks/alpha/drivers/odbc/CMakeLists.txt` test executable source list.
- Command evidence:
  - `cmake -S tracks/alpha/drivers/odbc -B tracks/alpha/drivers/odbc/build -DBUILD_TESTING=ON`
    -> `artifacts/enterprise-readiness/ODBC-006/cmake_configure.log`
  - `cmake --build tracks/alpha/drivers/odbc/build --target scratchbird_odbc -j 6`
    -> `artifacts/enterprise-readiness/ODBC-006/build_scratchbird_odbc.log`
- `ctest --test-dir tracks/alpha/drivers/odbc/build --output-on-failure`
    -> `artifacts/enterprise-readiness/ODBC-006/verification_tests.log`
    -> `artifacts/enterprise-readiness/ODBC-006/verification_20260223T024300Z.log`
- `cat artifacts/enterprise-readiness/ODBC-006/latest_verification.log` for evidence bundle.

## Blocker
- No blockers. Full bulk operation suite now exercised in `scratchbird_odbc_tests`.

## Files Touched
- `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`
- `tracks/alpha/drivers/odbc/tests/test_odbc_bulk_operations.cpp`
- `tracks/alpha/drivers/odbc/CMakeLists.txt`

## Next Step
- Continue to maintain this evidence as test coverage expands (including additional bulk scenarios).
