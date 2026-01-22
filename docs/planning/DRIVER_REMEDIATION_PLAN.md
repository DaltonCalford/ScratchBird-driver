# ScratchBird Driver Remediation Plan

Status: Draft
Last Updated: 2026-01-09

## Goal

Bring all drivers to native ScratchBird parity using SBWP v1.1, server-side
prepare/bind, full type coverage, and consistent metadata behavior.

## Dependencies

- SBWP v1.1 server implementation and conformance testing
- Stable sys.* catalog views for metadata queries
- Driver metadata contract in ScratchBird specs

## Phased Work

### Phase 0 - Documentation and Baseline

- Publish driver specs in `docs/specifications/`
- Align README claims with actual status
- Define a conformance test matrix (handshake, auth, prepare/bind, types)
- Implement Go in-language harness helper, then extract CLI adapter contract

### Phase 1 - Protocol Alignment (SBWP v1.1)

- Replace SBDB 12-byte header with SBWP 40-byte header
- Implement TLS 1.3 negotiation and enforce required modes
- Implement attachment_id/txn_id tracking and message headers
- Remove legacy message codes

### Phase 2 - Prepare/Bind Execution

- Add server-side PARSE/BIND/EXECUTE support in each driver
- Remove client-side SQL substitution for parameters
- Add BIND-based batch execution

### Phase 3 - Type Coverage

- Implement composite, geometry, macaddr, range decoding/encoding
- Validate array/vector parsing against SBWP type serialization
- Add type round-trip tests for each driver

### Phase 4 - Metadata and Schema

- Apply search_path/currentSchema on connect
- Implement sys.* metadata queries for schemas/tables/columns/indexes
- Populate JDBC DatabaseMetaData and similar APIs in other drivers

### Phase 5 - Cancellation and Robustness

- Implement CANCEL and timeout propagation in all drivers
- Add streaming result support where applicable
- Add integration tests for cancel, timeout, and large result sets

## Driver Checklists

### Go

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### Node.js

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### Python

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Apply search_path on connect
- [ ] Add cancel tests

### Rust

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### Ruby

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### PHP

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### R

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### Pascal

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Add schema/search_path support
- [ ] Add cancel tests

### .NET

- [ ] Replace SBDB protocol with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add missing wire types (composite/geometry/macaddr/range)
- [ ] Implement Cancel
- [ ] Add schema/search_path support

### JDBC

- [ ] Replace PG-style message set with SBWP v1.1
- [ ] Implement PARSE/BIND/EXECUTE
- [ ] Add sys.* metadata queries (getTables/getSchemas/getColumns)
- [ ] Apply currentSchema on connect
- [ ] Add cancel tests
