# Power BI Compatibility Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support ScratchBird Power BI connectivity at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `Power BI PostgreSQL / ODBC custom connector surface`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/integrations/scratchbird-powerbi`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/powerbi/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_POWERBI_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The lane may use ODBC where appropriate, but generic ODBC alone is not enough
  if a custom connector surface is required to meet benchmark expectations.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed the mainstream Power BI PostgreSQL user experience for import
  and refresh scenarios
- provide deterministic credential, metadata, and type behavior
- define clearly what is handled by the custom connector versus the underlying driver

## Required Compatibility Families

- Power Query connector bootstrap and credential handling
- metadata and type projection into the Power BI model
- query folding guidance where feasible
- diagnostics suitable for Desktop and gateway troubleshooting
- custom connector packaging when required

## Required Packaging And Integration Surface

- `.mez` custom connector packaging where required
- explicit underlying driver/ODBC prerequisites
- release-evidence staging at `release/readiness/powerbi/<version>/`
- installation and deployment guidance for Desktop and gateway scenarios

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `./bin/bootstrap`
2. contract and conformance: `./bin/test-contract`
3. performance: `./bin/test-perf`

## Implementation Sequence

1. connector architecture and credential flow
2. metadata/type behavior and folding strategy
3. diagnostics and refresh behavior
4. packaging and deployment guidance
5. release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the Power Query/custom connector surface
- define and implement the split between custom connector logic and underlying driver use
- implement packaging, deployment, and diagnostics guidance

### Server Blocked

- validate Desktop/gateway behavior against a live server
- publish compatibility and performance evidence
- prove refresh and folding behavior in real Power BI flows

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/powerbi.md`
- Getting started: `docs/getting-started/powerbi.md`
- Later verification packet: `docs/development/server-verification/powerbi.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

