# Airbyte Connector API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Airbyte PostgreSQL source/destination`
- Authoritative lane spec: `docs/application-reference/AIRBYTE_CONNECTOR_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/airbyte/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_AIRBYTE_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the connectors and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- ScratchBird Airbyte source connector
- ScratchBird Airbyte destination connector
- release evidence root: `release/readiness/airbyte/<version>/`

## Mandatory Integration Surface

- discovery, check, read, state, and incremental sync
- destination write and schema evolution handling
- Airbyte protocol compatibility for catalogs, records, and state messages

## Non-Optional Behaviors

- deterministic state/checkpoint behavior
- clear type mapping and schema evolution rules
- packaging suitable for Airbyte runtime registration

## Later Proof

- server verification packet: `docs/development/server-verification/airbyte.md`
- release evidence root: `release/readiness/airbyte/<version>/`

