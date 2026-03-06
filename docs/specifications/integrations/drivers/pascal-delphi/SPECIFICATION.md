# Pascal/Delphi Integration Specification

Status: Draft
Priority: P0
Category: Language Driver


Checklist: `docs/planning/driver-checklists/pascal.md` (see Integration Appendix Tasks)
## 1. Goals

- Define compatibility requirements for Pascal/Delphi.
- Specify driver/protocol features required for integration.

## 2. Integration Path

- Primary driver/protocol used.
- Authentication requirements.
- Metadata coverage.

## 3. Required Features

- TLS modes must support `sslmode=disable` (plaintext) and TLS-enabled modes (`allow`, `prefer`, `require`, `verify-ca`, `verify-full`) with policy enforcement in TLS modes.
- Startup feature negotiation must support `binary_transfer=false` and `compression=zstd` (`compression=none` normalizes to `off`; unsupported values are rejected).
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

- SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow.
- ConnectorType selects backend driver at runtime.

## 11. Code Examples

```pascal
Conn := TSQLConnector.Create(nil);
Conn.ConnectorType := 'scratchbird';
Query := TSQLQuery.Create(nil);
Query.SQL.Text := 'SELECT 1';
Query.Open;
```

## 12. Vendor-Specific Test Criteria

- Validate transaction behavior via TSQLTransaction.
- Confirm schema retrieval APIs (SQLDB) return expected shapes.

## 13. Implementation Checklist Appendix

- Driver checklist: `docs/planning/driver-checklists/pascal.md`
- [x] Constraint: SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow. (Driver task: `docs/planning/driver-checklists/pascal.md`)
- [x] Constraint: ConnectorType selects backend driver at runtime. (Driver task: `docs/planning/driver-checklists/pascal.md`)
- [x] Test: Validate transaction behavior via TSQLTransaction. (Driver task: `docs/planning/driver-checklists/pascal.md`)
- [x] Test: Confirm schema retrieval APIs (SQLDB) return expected shapes. (Driver task: `docs/planning/driver-checklists/pascal.md`)

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
