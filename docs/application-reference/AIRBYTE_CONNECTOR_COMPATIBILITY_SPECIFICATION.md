# Airbyte Connector Compatibility Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support ScratchBird Airbyte connectors at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `Airbyte PostgreSQL source/destination`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/integrations/scratchbird-airbyte`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/airbyte/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_AIRBYTE_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The Airbyte lane must cover both source and destination behavior, not just a
  one-way bridge.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed the PostgreSQL source/destination connector experience where
  ScratchBird is the remote system
- provide deterministic discovery, state, incremental sync, and write behavior
- package the connectors so they fit normal Airbyte runtime expectations

## Required Compatibility Families

- source connector discovery, read, state, and incremental sync behavior
- destination connector write and schema-handling behavior
- Airbyte protocol compatibility for catalogs, records, state, and messages
- type mapping and schema evolution expectations
- connector packaging and deployment surfaces

## Required Packaging And Integration Surface

- source and destination connector package identities
- connector runtime/deployment layout
- release-evidence staging at `release/readiness/airbyte/<version>/`
- platform registration and deployment guidance

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `./bin/bootstrap`
2. contract and conformance: `./bin/test-contract`
3. performance: `./bin/test-perf`

## Implementation Sequence

1. source connector bootstrap and discovery
2. destination connector bootstrap and write path
3. protocol/state/schema handling
4. packaging and deployment guidance
5. release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement source and destination connectors
- implement discovery, state, incremental sync, and write behavior
- implement packaging and deployment guidance

### Server Blocked

- validate source/destination behavior against a live ScratchBird server
- publish compatibility and performance evidence
- validate platform registration and runtime behavior in Airbyte

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/airbyte.md`
- Getting started: `docs/getting-started/airbyte.md`
- Later verification packet: `docs/development/server-verification/airbyte.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

