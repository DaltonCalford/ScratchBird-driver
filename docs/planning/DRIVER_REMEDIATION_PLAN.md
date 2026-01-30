# ScratchBird Driver Remediation Plan

Status: Complete
Last Updated: 2026-01-30

## Goal

Bring all drivers to native ScratchBird parity using SBWP v1.1, server-side
prepare/bind, binary-only transfer, streaming/paging, and consistent metadata
behavior.

## Inputs

- `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- `docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md`
- `docs/specifications/PREPARE_BIND_REQUIREMENTS.md`
- `docs/specifications/DRIVER_STREAMING_AND_PAGING.md`
- `docs/specifications/DRIVER_CANCELLATION_TIMEOUTS.md`
- `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`

## Phased Work

### Phase 0 - Baseline Alignment (Complete)

- [x] Publish driver specs in `docs/specifications/`
- [x] Align README claims with actual status
- [x] Define a conformance test matrix (handshake, auth, prepare/bind, types)
- [x] Implement Go in-language harness helper

### Phase 1 - Binary-Only Enforcement + DSN Coverage

- [x] Reject `binary_transfer=false` with SQLSTATE 0A000 in all drivers
- [x] Add DSN key support for `role` + `sslpassword` (per spec)
- [x] Ensure Superset/Metabase pass through binary-only defaults

### Phase 2 - Compression (zstd)

- [x] Disable compression negotiation until server support is ready (reject zstd)

Note: zstd compression + integration tests are deferred until server-side
compression is implemented.

### Phase 3 - Streaming + Portal Paging

- [x] Handle `MSG_PORTAL_SUSPENDED` and resume via EXECUTE max_rows
- [x] Add paging support to streaming APIs (fetch size, maxRows)
- [x] Update Python/R/JDBC to avoid full buffering; support incremental fetch
- [x] Add paging tests to the conformance harness

### Phase 4 - DESCRIBE + Metadata Fidelity

- [x] Send DESCRIBE after PARSE to populate parameter/result metadata
- [x] Use DESCRIBE results to validate parameter counts/types
- [x] Add tests for DESCRIBE flows

### Phase 5 - Timeout + Cancel Enforcement

- [x] .NET: wire CommandTimeout to timeoutMs/CANCEL
- [x] JDBC: enforce query timeout with CANCEL and surface 57014
- [x] Add tests for timeout-triggered CANCEL

### Phase 6 - Metadata Completeness (JDBC/Superset/Metabase)

- [x] JDBC: implement getPrimaryKeys/getImportedKeys/getTypeInfo from sys.*
- [x] Superset dialect: implement get_pk_constraint/get_foreign_keys/get_indexes
- [x] Superset: resolve type mapping via sys.types instead of raw ids
- [x] Metabase: align feature flags with actual JDBC metadata, or add missing
      metadata support first

## Driver Checklists

### Go

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Portal paging (MSG_PORTAL_SUSPENDED)

### Node.js

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Portal paging in queryStream + non-streamed queries

### Python

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Incremental fetch (avoid buffering in Cursor)
- [x] Portal paging for large results

### Ruby

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Portal paging in ResultStream

### Rust

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Parameterized streaming queries
- [x] Portal paging

### PHP

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Portal paging in ResultStream

### R

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Incremental fetch API (avoid buffering)
- [x] Portal paging

### Pascal

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Portal paging in ResultStream

### .NET

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role/sslpassword DSN keys
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] CommandTimeout -> timeoutMs/CANCEL
- [x] Portal paging

### JDBC

- [x] SBWP v1.1 + PARSE/BIND/EXECUTE
- [x] Enforce binary-only (reject binary_transfer=false)
- [x] Add role DSN key
- [x] Implement zstd or disable compression negotiation
- [x] DESCRIBE integration
- [x] Streaming via fetchSize (avoid full buffering)
- [x] Portal paging
- [x] Metadata: PK/FK/TypeInfo from sys.*

### Superset

- [x] Implement get_pk_constraint/get_foreign_keys/get_indexes
- [x] Resolve type names via sys.types rather than raw data_type_id
- [x] Align connection param names to DSN spec

### Metabase

- [x] Align feature flags with actual JDBC metadata coverage
- [x] Enforce binaryTransfer=true in connection details
