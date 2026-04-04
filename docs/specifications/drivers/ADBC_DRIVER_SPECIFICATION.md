# ADBC / Arrow Driver Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support the ScratchBird ADBC / Arrow driver at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `Apache Arrow ADBC PostgreSQL driver`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/drivers/adbc`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/adbc/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_ADBC_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- Implementation must not be weaker than the current JDBC/.NET baseline where
  the ADBC surface exposes equivalent capability families.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed the Arrow ADBC PostgreSQL driver for columnar interoperability
- preserve JDBC/.NET-class correctness for transactions, errors, and metadata
  where ADBC exposes equivalents
- treat Arrow-native exchange as first-class rather than a wrapper over row
  materialization

## Required Capability Families

- ADBC `Database`, `Connection`, and `Statement` lifecycle compatibility
- Arrow-native zero-copy export/import where possible
- bulk ingest, bind, and partitioned read support
- `GetInfo`, metadata, schema, and transaction surfaces
- stable ADBC status/error mapping
- compatibility with host-language wrappers above the C driver

## Required Packaging And Integration Surface

- native driver binary and headers for ADBC consumers
- driver-manager registration guidance
- release-evidence staging at `release/readiness/adbc/<version>/`
- explicit compatibility notes for Arrow/ADBC wrapper stacks

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `cmake -S . -B build && cmake --build build`
2. contract and conformance: `ctest --test-dir build --output-on-failure`
3. performance: `ctest --test-dir build -R perf --output-on-failure`

## Implementation Sequence

1. ADBC database/connection/statement lifecycle
2. Arrow export/import and bind support
3. metadata, `GetInfo`, and transaction behavior
4. driver-manager and packaging guidance
5. release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the native ADBC lane and Arrow bind/export paths
- implement metadata/info/status mapping
- implement packaging for direct and driver-manager consumption

### Server Blocked

- prove zero-copy and bulk-ingest behavior against a live server
- publish compatibility and performance evidence
- validate wrapper interoperability on top of the native lane

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/adbc.md`
- Getting started: `docs/getting-started/adbc.md`
- Later verification packet: `docs/development/server-verification/adbc.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

