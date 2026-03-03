# ODBC Baseline Requirement Mapping (S0)

Scope: `tracks/alpha/drivers/odbc` lane only.

Status legend:
- `Implemented`: source surface is present with direct lane test anchors.
- `Partial`: source surface is present but has a known gap in current implementation.

| ODBCBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN` (connection/session lifecycle) | `Implemented` | `src/odbc_driver.cpp:235`, `src/odbc_driver.cpp:251`, `src/odbc_handles.cpp:1790`, `tests/test_odbc_driver_integration.cpp:150`, `tests/test_odbc_external_runtime.cpp:77` |
| `TXN` | `JDBCBL-TXN` (autocommit, isolation, commit/rollback) | `Implemented` | `src/odbc_driver.cpp:890` (`SQLEndTran`), `src/odbc_handles.cpp:1774` (`OdbcEnvironment::endTransaction`), `src/odbc_handles.cpp:2389` (`OdbcConnection::endTransaction`), `tests/test_odbc_catalog_and_types.cpp:500`, `tests/test_odbc_catalog_and_types.cpp:530`, `tests/test_odbc_catalog_and_types.cpp:551` |
| `EXEC` | `JDBCBL-EXEC` (statement execution, binding, fetch) | `Implemented` | `src/odbc_driver.cpp:424`, `src/odbc_driver.cpp:492`, `src/odbc_driver.cpp:600`, `src/odbc_handles.cpp:3709`, `src/odbc_handles.cpp:3750`, `src/odbc_handles.cpp:3836`, `src/odbc_handles.cpp:6036`, `tests/test_odbc_driver_integration.cpp:182`, `tests/test_odbc_driver_integration.cpp:216`, `tests/test_odbc_bulk_operations.cpp:76`, `tests/test_odbc_catalog_and_types.cpp:589` |
| `META` | `JDBCBL-META` (catalog/metadata retrieval) | `Implemented` | `src/odbc_driver.cpp:705`, `src/odbc_driver.cpp:723`, `src/odbc_driver.cpp:757`, `src/odbc_handles.cpp:6060`, `src/odbc_handles.cpp:6204`, `src/odbc_handles.cpp:6574`, `tests/test_odbc_catalog_and_types.cpp:148`, `tests/test_odbc_catalog_and_types.cpp:177`, `tests/test_odbc_catalog_and_types.cpp:314` |
| `TYPE` | `JDBCBL-TYPE` (type info and value conversion) | `Implemented` | `src/odbc_driver.cpp:410`, `src/odbc_handles.cpp:2931`, `src/odbc_handles.cpp:4667`, `tests/test_odbc_type_info.cpp:13`, `tests/test_odbc_type_info.cpp:34`, `tests/test_odbc_catalog_and_types.cpp:342` |
| `ERR` | `JDBCBL-ERR` (diagnostics/state mapping) | `Implemented` | `src/odbc_driver.cpp:916`, `src/odbc_driver.cpp:983`, `src/odbc_driver.cpp:1524`, `src/odbc_handles.cpp:287`, `tests/test_odbc_unicode_compat.cpp:103`, `tests/test_odbc_unicode_compat.cpp:162` |
| `RES` | `JDBCBL-RES` (handle/statement/resource lifecycle) | `Implemented` | `src/odbc_driver.cpp:128`, `src/odbc_driver.cpp:180`, `src/odbc_driver.cpp:473`, `src/odbc_handles.cpp:2124`, `src/odbc_handles.cpp:3750`, `tests/test_odbc_driver_integration.cpp:228`, `tests/test_odbc_external_runtime.cpp:99` |
