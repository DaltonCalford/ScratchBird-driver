# dbt Adapter Compatibility Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support the ScratchBird dbt adapter at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `dbt-postgres`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/integrations/scratchbird-dbt-adapter`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/dbt/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_DBT_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The adapter must not be weaker than the current JDBC/.NET baseline when it
  traverses those underlying driver surfaces.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed `dbt-postgres` for model execution and developer ergonomics
- provide deterministic relation, quoting, and incremental semantics instead of
  a minimally working adapter
- support the modern analytics-stack entry point explicitly called out in the
  repo support goals

## Required Compatibility Families

- dbt-core adapter contract compatibility
- materializations for table, view, incremental, and ephemeral workflows
- seeds, snapshots, tests, docs generation, and relation caching
- type mapping, quoting, schema naming, and macro parity
- transaction and retry behavior safe for ScratchBird MGA semantics
- package and CI surfaces expected by dbt adapter consumers

## Required Packaging And Integration Surface

- Python package identity for the adapter
- dbt-core version compatibility matrix
- release-evidence staging at `release/readiness/dbt/<version>/`
- example project, profile, and CI guidance for adapter consumers

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `./bin/bootstrap`
2. contract and conformance: `./bin/test-contract`
3. performance: `./bin/test-perf`

## Implementation Sequence

1. adapter package skeleton and connection manager
2. relation, quoting, schema naming, and type mapping
3. materializations and incremental semantics
4. seeds, snapshots, tests, docs, and relation caching
5. packaging and release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the dbt adapter package and connection manager
- implement materializations and metadata/introspection flows
- implement packaging, examples, and CI guidance

### Server Blocked

- validate materializations, snapshots, docs, and tests against a live server
- publish compatibility and performance evidence
- prove behavior across supported dbt-core versions

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/dbt.md`
- Getting started: `docs/getting-started/dbt.md`
- Later verification packet: `docs/development/server-verification/dbt.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

