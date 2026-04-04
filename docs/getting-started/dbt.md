# dbt Adapter

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `dbt-postgres`
- Authoritative lane spec: `docs/application-reference/DBT_ADAPTER_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/dbt/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_DBT_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the adapter package, sample project, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/integrations/scratchbird-dbt-adapter`

## Planned Package Identity

- `dbt-scratchbird` adapter package
- release evidence path: `release/readiness/dbt/<version>/`

## First Implementation Focus

- implement adapter package and connection manager
- implement relation/naming/type behavior
- implement table/view/incremental materializations
- implement seeds, snapshots, tests, and docs support

## Later Smoke Scenarios

- `dbt debug`
- `dbt run`
- `dbt test`
- `dbt docs generate`

