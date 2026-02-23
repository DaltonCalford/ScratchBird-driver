# JDBC-202 Verification Notes (2026-02-23T04:27:21Z)

## Status
In progress. Large-lob and metadata coverage expanded in integration tests; protocol/unit coverage remains open for enterprise-grade protocol parity checks.

## What changed
- Added JDBC integration coverage for 6 MiB BLOB roundtrip via `PreparedStatement#setBytes` + `ResultSet#getBytes`.
- Added JDBC integration coverage for 3 MiB CLOB/text roundtrip via `PreparedStatement#setObject(..., Types.CLOB)`.
- These tests validate large value serialization + end-to-end result materialization paths and partial memory-path correctness.
- Added metadata result-set column-order assertions for `getTables(null,null,"% ",null)` and prepared-statement replay after schema recreate.

## Evidence
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_integration_20260223T042530Z.log`
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_protocol_unit_20260223T040748Z.log`
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_integration_20260223T042721Z.log` (current run with metadata/replay coverage)

## Remaining work
- Extend to nested/derived metadata families (columns with complex types) and replay behavior under transient reset/failover conditions.
