# ODBC-006 Verification Notes

Status: Code complete (verification blocked by missing in-tree GoogleTest dependency).

## Evidence
- Implemented row-aware bulk parameter materialization in `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`.
- Added `OdbcStatement::buildParameterData(std::vector<ParameterLiteral>&, SQLULEN)` and routed `execute` through it for row 0.
- Added `SQLBulkOperations` path that loops through rowset, executes each bound row, and writes:
  - `SQL_PARAM_SUCCESS` / `SQL_PARAM_ERROR` / `SQL_PARAM_SUCCESS_WITH_INFO`
  - `params_processed_ptr_` and `rows_fetched_ptr_`
- Added unsupported-operation guard (`operation != SQL_ADD`) returning `SQL_ERROR` + `HYC00`.
- Removed duplicated stubbed `bulkOperations` definition.
- Added tests in `tracks/alpha/drivers/odbc/tests/test_odbc_bulk_operations.cpp`:
  - `BulkOperationsExecutesEachRowInOrder`
  - `BulkOperationsUsesBindOffsetInArrayAddressing`
  - `BulkOperationsRejectsUnsupportedOperationCode`
- Wired new bulk test file into `tracks/alpha/drivers/odbc/CMakeLists.txt` test executable source list.
- Command evidence:
  - `cmake -S . -B build -DBUILD_TESTING=ON` -> `artifacts/enterprise-readiness/ODBC-006/cmake_configure.log`
  - `cmake --build build --target scratchbird_odbc -j 6` -> `artifacts/enterprise-readiness/ODBC-006/build_scratchbird_odbc.log`

## Blocker
- CTest reports no executable tests (`scratchbird_odbc_tests`) because GoogleTest is not available in-tree to configure the ODBC test target.

## Files Touched
- `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`
- `tracks/alpha/drivers/odbc/tests/test_odbc_bulk_operations.cpp`
- `tracks/alpha/drivers/odbc/CMakeLists.txt`

## Next Step
- Once GTest is available in-tree, run:
  - `ctest --test-dir build --output-on-failure` and capture full bulk operation assertion output.
