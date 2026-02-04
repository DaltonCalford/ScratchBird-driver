# C/C++ Integration Specification

Status: Draft
Priority: P2
Category: Language Driver

## 1. Goals

- Define compatibility requirements for C/C++.
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

- Provide a stable C API façade for language bindings where ABI stability is required.
- Support both static and shared builds with explicit linkage flags.
- Document ownership of buffers returned to callers.

## 11. Code Examples

```cpp
sb::Connection conn{"sb://user:pass@localhost:3092/db"};
auto rows = conn.query("SELECT 1");
```

## 12. Vendor-Specific Test Criteria

- Verify both static and shared builds link successfully.
- Validate row buffers remain valid until the next fetch call.

## 13. Implementation Checklist Appendix

- Driver checklist: `docs/planning/driver-checklists/cpp.md`
- [ ] Constraint: Provide a stable C API façade for language bindings where ABI stability is required. (Driver task: `docs/planning/driver-checklists/cpp.md`)
- [ ] Constraint: Support both static and shared builds with explicit linkage flags. (Driver task: `docs/planning/driver-checklists/cpp.md`)
- [ ] Constraint: Document ownership of buffers returned to callers. (Driver task: `docs/planning/driver-checklists/cpp.md`)
- [ ] Test: Verify both static and shared builds link successfully. (Driver task: `docs/planning/driver-checklists/cpp.md`)
- [ ] Test: Validate row buffers remain valid until the next fetch call. (Driver task: `docs/planning/driver-checklists/cpp.md`)

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
