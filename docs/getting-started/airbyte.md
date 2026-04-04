# Airbyte Connector

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Airbyte PostgreSQL source/destination`
- Authoritative lane spec: `docs/application-reference/AIRBYTE_CONNECTOR_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/airbyte/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_AIRBYTE_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the connectors, container/runtime assets, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/integrations/scratchbird-airbyte`

## Planned Package Identity

- source and destination ScratchBird Airbyte connectors
- release evidence path: `release/readiness/airbyte/<version>/`

## First Implementation Focus

- implement connector check/discovery
- implement source read/state/incremental sync
- implement destination write/schema handling
- implement packaging/runtime registration guidance

## Later Smoke Scenarios

- connector `check`
- connector `discover`
- representative source sync
- representative destination write

