# ScratchBird Driver Remediation Plan

Status: In Progress
Last Updated: 2026-02-04

## Goal

Bring all drivers and adapters to full SBWP v1.1 conformance with server-side
prepare/bind, binary-only transfer, complete type coverage, and consistent
metadata behavior.

## Inputs

- `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- `docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md`
- `docs/specifications/PREPARE_BIND_REQUIREMENTS.md`
- `docs/specifications/DRIVER_STREAMING_AND_PAGING.md`
- `docs/specifications/DRIVER_CANCELLATION_TIMEOUTS.md`
- `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`
- ScratchBird server source: `ScratchBird/src/catalog/sys_catalog.cpp`

## Phased Work

### Phase 0 - Audit + Status Alignment

- [x] Refresh driver implementation audit
- [x] Update README claims to reflect current state
- [x] Update per-driver checklists for all drivers (including Dart/Swift/Elixir/Mojo/C++)

### Phase 1 - Core Drivers Hardening

Core drivers: Go, Node, Python, Ruby, Rust, PHP, R, Pascal, .NET, JDBC, ODBC.

- [x] Binary-only enforcement (reject `binary_transfer=false`)
- [x] Compression rejection (`compression=zstd`)
- [x] Server-side prepare/bind + DESCRIBE integration
- [x] Portal paging support
- [x] sys.* metadata helpers (language drivers) and JDBC/ODBC mappings
- [ ] Replace SQLSTATE class-prefix error mapping with full SQLSTATE mapping (all core drivers)

### Phase 2 - New Drivers (Dart/Swift/Elixir/Mojo)

- [ ] Enforce TLS required (reject `sslmode=disable`)
- [ ] Enforce binary-only (reject `binary_transfer=false`)
- [ ] Reject compression=zstd until server support exists
- [ ] Complete type matrix (arrays, composites, vector, inet/cidr/macaddr, range/composite wrappers)
- [ ] Add sys.* metadata helper APIs
- [ ] Add conformance/integration tests

Driver-specific blockers:
- Swift: implement TLS transport (currently TCP only)
- Mojo: remove Python bridge; implement native SBWP client

### Phase 3 - C/C++ Client Coverage

- [ ] Expand C API type coverage to full SBWP matrix
- [ ] Expose SET_OPTION and PING helpers in C API
- [ ] Add sys.* metadata helper queries or bindings

### Phase 4 - BI Drivers (Superset/Metabase)

- [ ] Superset: use `sys.columns.data_type_name` directly (remove numeric fallback)
- [ ] Metabase: revalidate feature flags against JDBC metadata and adjust

### Phase 5 - CLI Conformance

- [ ] Audit `sb_isql` and conformance runner against SBWP v1.1 harness

## Audit Gaps (2026-02-04)

### Type Mapping Audit (TYPE_MAPPING_MATRIX.md)

- [ ] C++: expand type mapping beyond core primitives
- [ ] Dart: add arrays, composite, vector, inet/cidr/macaddr, range wrappers
- [ ] Swift: add arrays, composite, range, inet/cidr/macaddr, vector
- [ ] Elixir: add arrays, composite, vector, inet/cidr/macaddr
- [ ] Mojo: native type wrappers and binary decoding

### Error Mapping Audit (DRIVER_ERROR_MAPPING.md)

- [ ] All drivers: replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

### Metadata Contract Audit (METADATA_SCHEMA_CONTRACT.md, DRIVER_METADATA_JDBC_ODBC_MAPPING.md)

- [ ] Dart: add sys.* metadata helpers
- [ ] Swift: add sys.* metadata helpers
- [ ] Elixir: add sys.* metadata helpers
- [ ] Mojo: add sys.* metadata helpers (native)

## Driver Checklists

Per-driver checklists live in `docs/planning/driver-checklists/`.
