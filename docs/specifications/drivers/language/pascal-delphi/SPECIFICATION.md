# Pascal/Delphi Driver Specification

Status: Draft
Priority: P0

## 1. Goals

- Provide a native SBWP v1.1 driver with idiomatic Pascal/Delphi APIs.
- Conform to the language standard interface where applicable.
- Meet the shared ScratchBird driver requirements.

## 2. Scope

- Native SBWP v1.1 connectivity.
- Prepared statements and parameter binding.
- Metadata helpers per sys.* contract.
- Error mapping and cancellation semantics.

## 3. Non-Goals

- Emulated protocol drivers (PostgreSQL/MySQL/Firebird/MSSQL).
- Server-side UDR connectors.

## 4. Required Features

- TLS modes must support `sslmode=disable` (plaintext) and TLS-enabled modes (`allow`, `prefer`, `require`, `verify-ca`, `verify-full`) with policy enforcement in TLS modes.
- Startup feature negotiation must support `binary_transfer=false` and `compression=zstd` (`compression=none` normalizes to `off`; unsupported values are rejected).
- Full SBWP v1.1 message coverage for parse/bind/execute, ready/paging.
- SQLSTATE mapping must be spec-complete and surfaced in errors.
- Metadata helpers must use sys.* contract and return stable schemas.
- All wire types in TYPE_MAPPING_MATRIX.md must encode and decode.
- Streaming/paging must honor fetch_size and row batching.
- Timeouts/cancel semantics must follow DRIVER_CANCELLATION_TIMEOUTS.md.

## 5. Type Mapping

- Full encode/decode for all wire types in TYPE_MAPPING_MATRIX.md.
- Preserve round-trip fidelity for composite, range, geometry, and vector.

## 6. Metadata Contract

- Implement METADATA_SCHEMA_CONTRACT.md as the source of truth.
- Use DRIVER_METADATA_JDBC_ODBC_MAPPING.md for JDBC/ODBC compatible shapes.

## 7. Error Mapping

- Implement SQLSTATE mapping per DRIVER_ERROR_MAPPING.md.
- Surface message, sqlstate, detail, hint, and retriable flag.

## 8. Security Requirements

- TLS 1.3 preferred with server certificate validation.
- Credential handling must avoid logging secrets.
- Connection strings must support secure credential sources.

## 9. Observability Requirements

- Expose connection state and last SQLSTATE for debugging.
- Provide lightweight logging hooks (disabled by default).

## 10. Performance Requirements

- Avoid per-row allocations in hot loops.
- Use buffered I/O for network reads and writes.
- Support prepared statement reuse and pooled connections.

## 11. Conformance & Testing

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.


## 12. System Constraints & Vendor Quirks

- SQLDB uses TSQLConnector/TSQLConnection with TSQLTransaction to manage transactions.
- TSQLQuery is the primary dataset for executing queries and reading results.

## 13. Code Examples

```pascal
Conn := TSQLConnector.Create(nil);
Conn.ConnectorType := 'scratchbird';
Txn := TSQLTransaction.Create(nil);
Txn.DataBase := Conn;
Query := TSQLQuery.Create(nil);
Query.Database := Conn;
Query.Transaction := Txn;
Query.SQL.Text := 'SELECT 1';
Query.Open;
```

## 14. Vendor-Specific Test Criteria

- Validate transaction handling via TSQLTransaction.
- Ensure schema retrieval APIs return expected metadata.

## 15. References

- docs/specifications/NATIVE_PROTOCOL_ALIGNMENT.md
- docs/specifications/TYPE_MAPPING_MATRIX.md
- docs/specifications/DRIVER_ERROR_MAPPING.md
- docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md
- docs/specifications/METADATA_SCHEMA_CONTRACT.md
- docs/specifications/DRIVER_PARAMETER_ENCODING.md
- docs/specifications/DRIVER_RESULT_DECODING.md
- docs/specifications/DRIVER_STREAMING_AND_PAGING.md
- docs/specifications/DRIVER_THREAD_SAFETY_POOLING.md
- docs/specifications/DRIVER_CANCELLATION_TIMEOUTS.md
- docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md
