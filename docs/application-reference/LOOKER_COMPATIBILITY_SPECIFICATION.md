# Looker Compatibility Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support ScratchBird Looker connectivity at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `Looker PostgreSQL dialect`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/integrations/scratchbird-looker`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/looker/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_LOOKER_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The lane may rely on underlying JDBC/driver surfaces, but the dialect and
  modeling contract must be first-class and explicit.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed the Looker PostgreSQL dialect for connection, SQL generation,
  and PDT-oriented behavior
- provide deterministic type and metadata behavior for explores and SQL Runner
- define clearly how the Looker-facing layer interacts with the underlying driver

## Required Compatibility Families

- connection configuration and credential handling
- SQL/dialect behavior expected by Looker PostgreSQL deployments
- metadata/type compatibility for explores and SQL Runner
- PDT-friendly DDL and persistence behavior
- packaging and deployment guidance for supported Looker environments

## Required Packaging And Integration Surface

- Looker connection/dialect package or deployment bundle as needed
- explicit underlying driver prerequisites
- release-evidence staging at `release/readiness/looker/<version>/`
- deployment guidance and supported-version matrix

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `./bin/bootstrap`
2. contract and conformance: `./bin/test-contract`
3. performance: `./bin/test-perf`

## Implementation Sequence

1. dialect and connection bootstrap
2. SQL generation and type behavior
3. PDT behavior and metadata coverage
4. deployment guidance and release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the Looker-facing dialect/connection layer
- implement SQL/dialect, metadata, and PDT behavior
- implement deployment guidance and compatibility packaging

### Server Blocked

- validate SQL Runner, explores, and PDT behavior against a live server
- publish compatibility and performance evidence
- prove installation/runtime behavior in supported Looker environments

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/looker.md`
- Getting started: `docs/getting-started/looker.md`
- Later verification packet: `docs/development/server-verification/looker.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

