# dapper Integration Specification

Status: Draft
Priority: P1
Category: ORM/Framework

## 1. Goals

- Define compatibility requirements for dapper.
- Specify driver/protocol features required for integration.

## 2. Integration Path

- Primary driver/protocol used.
- Authentication requirements.
- Metadata coverage.

## 3. Required Features

- TLS required; reject plaintext or sslmode=disable.
- Binary-only parameter binding enforced; reject binary_transfer=false.
- Full SBWP v1.1 message coverage for parse/bind/execute, ready/paging.
- SQLSTATE mapping must be spec-complete and surfaced in errors.
- Metadata helpers must use sys.* contract and return stable schemas.
- All wire types in TYPE_MAPPING_MATRIX.md must encode and decode.
- Streaming/paging must honor fetch_size and row batching.
- Timeouts/cancel semantics must follow DRIVER_CANCELLATION_TIMEOUTS.md.

## 4. Security & Compliance

- TLS 1.3 preferred with server certificate validation.
- Credential handling must avoid logging secrets.
- Connection strings must support secure credential sources.

## 5. Observability

- Expose connection state and last SQLSTATE for debugging.
- Provide lightweight logging hooks (disabled by default).

## 6. Performance Expectations

- Avoid per-row allocations in hot loops.
- Use buffered I/O for network reads and writes.
- Support prepared statement reuse and pooled connections.

## 7. Compatibility Notes

- Validate SQL dialect assumptions with ScratchBird.
- Ensure parameter binding uses SBWP binary-only encoding.

## 8. Testing

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.


## 10. System Constraints & Vendor Quirks

- Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection.
- Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming.
- Ensure parameter binding supports anonymous objects and `DynamicParameters`.

## 11. Code Examples

```csharp
using var conn = new ScratchBirdConnection(connString);
var rows = conn.Query<(int Id, string Name)>("select id, name from users");
```

## 12. Vendor-Specific Test Criteria

- Validate Dapper multi-mapping (`splitOn`) with joined queries.
- Ensure `QueryMultiple` works with multiple result sets.

## 13. Implementation Checklist Appendix

- Driver checklist: `docs/planning/driver-checklists/dotnet.md`
- [ ] Constraint: Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection. (Driver task: `docs/planning/driver-checklists/dotnet.md`)
- [ ] Constraint: Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming. (Driver task: `docs/planning/driver-checklists/dotnet.md`)
- [ ] Constraint: Ensure parameter binding supports anonymous objects and `DynamicParameters`. (Driver task: `docs/planning/driver-checklists/dotnet.md`)
- [ ] Test: Validate Dapper multi-mapping (`splitOn`) with joined queries. (Driver task: `docs/planning/driver-checklists/dotnet.md`)
- [ ] Test: Ensure `QueryMultiple` works with multiple result sets. (Driver task: `docs/planning/driver-checklists/dotnet.md`)

## 14. References

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
