# JDBC-202 Verification Notes (2026-02-23T04:52:03Z)

## Status
Verification complete for the scoped JDBC-202 contract.

## What changed
- Added JDBC integration coverage for 6 MiB BLOB roundtrip via `PreparedStatement#setBytes` + `ResultSet#getBytes`.
- Added JDBC integration coverage for 3 MiB CLOB/text roundtrip via `PreparedStatement#setObject(..., Types.CLOB)`.
- These tests validate large value serialization + end-to-end result materialization paths and partial memory-path correctness.
- Added metadata result-set column-order assertions for `getTables(null,null,"% ",null)` and prepared-statement replay after schema recreate.
- Implemented metadata contract methods for JDBC type objects:
  - `getUDTs`
  - `getSuperTypes`
  - `getSuperTables`
  - `getAttributes`
  - `getPseudoColumns`
- Expanded protocol retry detection for cached statement errors by adding 26000/34000 state support and message variants (`portal does not exist`, `cache lookup failed for`).
- Added failover-replay query path coverage for transient transport-state SQL errors (`08xx` / `SQLTransientConnectionException`) with at-most-once retry after reconnect.

## Evidence
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_integration_20260223T042530Z.log`
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_protocol_unit_20260223T040748Z.log`
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_integration_20260223T042721Z.log` (current run with metadata/replay coverage)
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_integration_20260223T044302Z.log` (metadata contract coverage refresh, includes pseudo-columns)
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_integration_20260223T044329Z.log` (protocol refresh, includes prepared-statement retry case)
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_protocol_unit_20260223T044330Z.log` (full module test refresh)
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_protocol_unit_20260223T045150Z.log` (failover/replay and protocol unit coverage)
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_full_20260223T045148Z.log` (full module verification after final JDBC-202 changes)
- `artifacts/enterprise-readiness/JDBC-202/verification_jdbc_full_20260223T045245Z.log` (latest full module verification with no source changes)

## Remaining work
- None in JDBC-202 scope.
