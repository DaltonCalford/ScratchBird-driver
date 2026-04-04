# Power BI Connector

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Power BI PostgreSQL / ODBC custom connector surface`
- Authoritative lane spec: `docs/application-reference/POWERBI_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/powerbi/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_POWERBI_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the connector package, deployment assets, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/integrations/scratchbird-powerbi`

## Planned Package Identity

- ScratchBird Power BI / Power Query connector package
- release evidence path: `release/readiness/powerbi/<version>/`

## First Implementation Focus

- define connector architecture and credential flow
- implement metadata/type behavior and diagnostics
- define folding behavior and caveats
- package connector for Desktop/gateway deployment

## Later Smoke Scenarios

- connector install and registration
- connect from Power BI Desktop
- import/refresh representative model
- inspect diagnostics for failed queries

