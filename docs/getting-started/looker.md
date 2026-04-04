# Looker Connector

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Looker PostgreSQL dialect`
- Authoritative lane spec: `docs/application-reference/LOOKER_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/looker/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_LOOKER_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the dialect package, deployment guidance, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/integrations/scratchbird-looker`

## Planned Package Identity

- ScratchBird Looker dialect/deployment package
- release evidence path: `release/readiness/looker/<version>/`

## First Implementation Focus

- define connection and dialect architecture
- implement SQL/dialect and metadata/type behavior
- implement PDT behavior and caveats
- implement deployment guidance

## Later Smoke Scenarios

- establish a Looker connection
- run SQL Runner queries
- run representative explore queries
- create and refresh PDTs

