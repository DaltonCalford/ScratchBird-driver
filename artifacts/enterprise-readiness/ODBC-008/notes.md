# ODBC-008 Verification Notes

Status: Code complete in-tree code changes applied.

## Evidence
- `cmake --build build --target scratchbird_odbc -j 4`
- `SQLGetInfo` and `SQLGetFunctions` outputs were tightened:
  - Removed unsupported ids from hard-coded advertised function list.
  - Fixed support bitmap clear size (`250 * sizeof(SQLUSMALLINT)`).

## Blocker
- Could not run full Info matrix/capability false-positive suite in-tree:
  - `Could NOT find GTest` during configure.
  - No ODBC capability-matrix test executable is currently available in this build configuration.
