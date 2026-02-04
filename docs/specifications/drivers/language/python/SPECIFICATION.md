# Python Driver Specification (Template)

Status: Draft (Template)
Target: Alpha/Beta

## 1. Goals

- Provide a native SBWP driver with idiomatic language APIs.
- Conform to the language standard interface.
- Satisfy shared driver requirements (auth, error mapping, metadata, paging).

## 2. Non-Goals

- Emulated protocol drivers (PostgreSQL/MySQL/Firebird/MSSQL).
- Server-side UDR connectors.

## 3. Required Features

- Connection management (connect/disconnect/reconnect)
- TLS required + binary-only parameter binding
- Prepared statements + parameter binding
- Transaction control (BEGIN/COMMIT/ROLLBACK)
- Metadata helpers (sys.*)
- Streaming/paging support
- SQLSTATE error mapping per DRIVER_ERROR_MAPPING

## 4. API Surface (Template)

- Connect: `connect(...)`
- Query: `query(sql, params)`
- Execute: `execute(sql, params)`
- Prepare: `prepare(sql)`
- Transaction: `begin/commit/rollback`
- Close: `close()`

## 5. Type Mapping

Must fully implement TYPE_MAPPING_MATRIX.md for encode + decode.

## 6. Metadata Contract

Use METADATA_SCHEMA_CONTRACT.md + DRIVER_METADATA_JDBC_ODBC_MAPPING.md.

## 7. Error Mapping

Implement spec-complete SQLSTATE mapping and surface driver-specific errors.

## 8. Conformance

Run DRIVER_CONFORMANCE_TEST_HARNESS.md with `sbdriver-conformance` adapter.

## 9. Open Questions

- TBD: Language-specific pooling defaults
- TBD: Async/await support and cancellation
