# Tableau Compatibility Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support ScratchBird Tableau connectivity at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `Tableau PostgreSQL / Named Connector SDK`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/integrations/scratchbird-tableau`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/tableau/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_TABLEAU_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The lane may use generic connectivity where sufficient, but must escalate to a
  true Tableau connector surface where that is required to meet benchmark expectations.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed the mainstream Tableau PostgreSQL experience for live and
  extract workflows
- provide deterministic metadata, auth, and capability behavior
- define clearly when native Tableau connector packaging is required

## Required Compatibility Families

- connection bootstrap and auth/SSL behavior
- metadata discovery for schemas, tables, columns, and capabilities
- live query and extract-friendly behavior
- diagnostics and operational setup guidance
- connector packaging and deployment where required

## Required Packaging And Integration Surface

- Tableau connector artifact/package where required
- explicit underlying driver prerequisites where applicable
- release-evidence staging at `release/readiness/tableau/<version>/`
- installation and deployment guidance for supported Tableau environments

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `./bin/bootstrap`
2. contract and conformance: `./bin/test-contract`
3. performance: `./bin/test-perf`

## Implementation Sequence

1. connector architecture and auth bootstrap
2. metadata/type/capability behavior
3. live/extract behavior and diagnostics
4. packaging and deployment guidance
5. release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the Tableau connectivity surface and any required native connector
- implement metadata, capability, and diagnostics behavior
- implement packaging and deployment guidance

### Server Blocked

- validate live and extract behavior against a live server
- publish compatibility and performance evidence
- prove installation and runtime behavior in supported Tableau environments

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/tableau.md`
- Getting started: `docs/getting-started/tableau.md`
- Later verification packet: `docs/development/server-verification/tableau.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

