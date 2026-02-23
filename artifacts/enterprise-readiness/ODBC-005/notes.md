# ODBC-005 Verification Notes

Status: In progress (verification blocked by missing ODBC test target in-tree).

## Evidence
- Implemented `OdbcStatement::setPos` in `tracks/alpha/drivers/odbc/src/odbc_handles.cpp` with support for:
  - `SQL_POSITION` and `SQL_REFRESH` repositioning/refresh pathways.
  - Concurrency-gated `SQL_UPDATE` and `SQL_DELETE` operations.
  - `SQL_DELETE` support for `SQL_ENTIRE_ROWSET`.
  - Forward-only cursor restriction for positioned operations (all positioned operations rejected).
  - Forward-only scroll restriction in `SQLFetchScroll` (`SQL_FETCH_NEXT` only).
- Added `tracks/alpha/drivers/odbc/tests/test_odbc_cursor_operations.cpp` with cursor behavior coverage for:
  - forward-only fetch restrictions,
  - positioned update/delete/refresh on scrollable cursors,
  - rowset delete and invalid-row/invalid-operation handling.
- `cd tracks/alpha/drivers/odbc && cmake --build build --target scratchbird_odbc -j 4` completed successfully.
- `cd tracks/alpha/drivers/odbc && cmake -S tracks/alpha/drivers/odbc -B tracks/alpha/drivers/odbc/build -DBUILD_TESTING=ON && cmake --build tracks/alpha/drivers/odbc/build && ctest --test-dir tracks/alpha/drivers/odbc/build --output-on-failure` completed; CMake reported missing GTest and test target was not registered.
- GTest is not discovered in current workspace.

## Blocker
- ODBC cursor tests are prepared but not executed end-to-end due missing CTest/driver test target and GTest dependency in the current build.

## Next Step
- Enable test build wiring under `tracks/alpha/drivers/odbc` (when GTest is available) and execute:
  - `FetchScrollHonorsForwardOnlyCursorType`
  - `ForwardOnlyBlocksNonPositionalSetPosOperations`
  - `SetPosSupportsPositionRefreshUpdateDelete`
  - `SetPosSupportsDeleteEntireRowset`
  - `SetPosRejectsInvalidRowsAndUnsupportedOps`
