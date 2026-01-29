# ScratchBird Driver Remediation Plan

Status: Complete (buffered streaming remains in Python/R/JDBC)
Last Updated: 2026-02-06

## Goal

Bring all drivers to native ScratchBird parity using SBWP v1.1, server-side
prepare/bind, full type coverage, and consistent metadata behavior.

## Dependencies

- SBWP v1.1 server implementation and conformance testing
- Stable sys.* catalog views for metadata queries
- Driver metadata contract in ScratchBird specs

## Phased Work

### Phase 0 - Documentation and Baseline

- [x] Publish driver specs in `docs/specifications/`
- [x] Align README claims with actual status
- [x] Define a conformance test matrix (handshake, auth, prepare/bind, types)
- [x] Implement Go in-language harness helper, then extract CLI adapter contract

### Phase 1 - Protocol Alignment (SBWP v1.1)

- [x] Replace SBDB 12-byte header with SBWP 40-byte header
- [x] Implement TLS 1.3 negotiation and enforce required modes
- [x] Implement attachment_id/txn_id tracking and message headers
- [x] Remove legacy message codes

### Phase 2 - Prepare/Bind Execution

- [x] Add server-side PARSE/BIND/EXECUTE support in each driver
- [x] Remove client-side SQL substitution for parameters
- [x] Add BIND-based batch execution

### Phase 3 - Type Coverage

- [x] Implement composite, geometry, macaddr, range decoding/encoding
- [x] Validate array/vector parsing against SBWP type serialization
- [x] Add type round-trip tests for each driver

### Phase 4 - Metadata and Schema

- [x] Apply search_path/currentSchema on connect
- [x] Implement sys.* metadata queries for schemas/tables/columns/indexes
- [x] Populate JDBC DatabaseMetaData and similar APIs in other drivers
- [x] Expose sys.* monitoring views (sessions/locks/statements/jobs/performance) as SYSTEM VIEW in metadata APIs

### Phase 5 - Cancellation and Robustness

- [x] Implement CANCEL and timeout propagation in all drivers
- [x] Add streaming result support where applicable (QueryStream/ResultStream/DataReader; Python/R/JDBC still buffer in-memory)
- [x] Add integration tests for cancel, timeout, and large result sets

## Driver Checklists

### Go

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### Node.js

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### Python

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Apply search_path on connect
- [x] Add cancel tests

### Rust

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### Ruby

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### PHP

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### R

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### Pascal

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Add schema/search_path support
- [x] Add cancel tests

### .NET

- [x] Replace SBDB protocol with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add missing wire types (composite/geometry/macaddr/range)
- [x] Implement Cancel
- [x] Add schema/search_path support

### JDBC

- [x] Replace PG-style message set with SBWP v1.1
- [x] Implement PARSE/BIND/EXECUTE
- [x] Add sys.* metadata queries (getTables/getSchemas/getColumns)
- [x] Apply currentSchema on connect
- [x] Add cancel tests
