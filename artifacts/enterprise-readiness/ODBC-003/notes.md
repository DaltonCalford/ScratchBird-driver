# ODBC-003 Verification Notes

Status: Code complete in-tree. Verification blocked by missing ODBC descriptor conformance test target in this repository.

## Evidence
- `cmake --build build --target scratchbird_odbc -j 4`
  - Output:
    - `Built target scratchbird_client`
    - `Built target scratchbird_odbc`
  - Log: `artifacts/enterprise-readiness/ODBC-003/build_scratchbird_odbc.log`
- Descriptor metadata path updates implemented:
  - `OdbcStatement::bindParameter` writes APD/IPD metadata fields for each bound parameter.
  - `OdbcStatement::bindCol` writes ARD/IRD metadata + type/nullability/display/searchable metadata for each bound column.
  - `OdbcStatement::setAttribute/getAttribute` now handles statement descriptor attributes.
  - `OdbcDescriptor::setField/getField/getRec/setRec` expanded for descriptor headers/records and improved validation.

## Remaining Verification Blocker
- `tracks/alpha/drivers/odbc/tests/test_odbc_capabilities_browse.cpp` (and any descriptor-conformance tests) are not wired to an in-tree CTest target.
- `find_package(GTest)` / test runner integration is not available in the current build configuration.

