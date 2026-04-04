# Flight SQL Driver Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support the ScratchBird Flight SQL driver at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `Apache Arrow Flight SQL client stack`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/drivers/flightsql`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/flightsql/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_FLIGHTSQL_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The lane must not weaken auth, session, metadata, or error behavior merely
  because it is analytical and Arrow-native.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- meet or exceed the open Flight SQL client expectations for correctness and throughput
- bridge to ScratchBird analytical features without weakening auth, error, or metadata behavior
- provide a first-class columnar client path rather than relying on JDBC as an intermediary

## Required Capability Families

- Flight SQL transport/session bootstrap over ScratchBird-native semantics
- query, prepared statement, and metadata operations
- Arrow stream handling and partitioned read support
- TLS/auth/channel configuration and cancellation behavior
- transaction coordination where the host surface exposes it
- analytical export/import behavior suitable for BI and data-science stacks

## Required Packaging And Integration Surface

- Flight SQL client package and headers/runtime deliverables as appropriate
- release-evidence staging at `release/readiness/flightsql/<version>/`
- explicit interoperability guidance for Arrow and Flight client ecosystems

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `cmake -S . -B build && cmake --build build`
2. contract and conformance: `ctest --test-dir build --output-on-failure`
3. performance: `ctest --test-dir build -R perf --output-on-failure`

## Implementation Sequence

1. transport/session bootstrap and auth
2. query and prepared-statement lifecycle
3. Arrow stream handling and partitioned reads
4. metadata, cancellation, and diagnostics
5. packaging and release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the Flight SQL transport/client
- implement query, prepared-statement, metadata, and cancellation operations
- implement packaging and interoperability guidance

### Server Blocked

- prove query/cancel/partition behavior against a live server
- publish compatibility and performance evidence
- validate integration with Arrow/Flight client tooling

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/flightsql.md`
- Getting started: `docs/getting-started/flightsql.md`
- Later verification packet: `docs/development/server-verification/flightsql.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

