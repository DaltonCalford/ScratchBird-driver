# Tableau Connector

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Tableau PostgreSQL / Named Connector SDK`
- Authoritative lane spec: `docs/application-reference/TABLEAU_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/tableau/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_TABLEAU_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the connector package, deployment assets, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/integrations/scratchbird-tableau`

## Planned Package Identity

- ScratchBird Tableau connector package
- release evidence path: `release/readiness/tableau/<version>/`

## First Implementation Focus

- define connector architecture and auth flow
- implement metadata and capability behavior
- implement live/extract behavior and diagnostics
- implement packaging and deployment guidance

## Later Smoke Scenarios

- connector install and registration
- connect from Tableau
- browse metadata and run a live query
- create and refresh an extract

