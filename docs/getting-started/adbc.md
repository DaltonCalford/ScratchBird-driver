# ADBC / Arrow Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Apache Arrow ADBC PostgreSQL driver`
- Authoritative lane spec: `docs/specifications/drivers/ADBC_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/adbc/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_ADBC_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but no native driver artifacts or live evidence exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/drivers/adbc`

## Planned Package Identity

- native ADBC driver binary and headers
- release evidence path: `release/readiness/adbc/<version>/`

## First Implementation Focus

- implement database/connection/statement lifecycle
- implement Arrow bind and export/import flows
- implement metadata and `GetInfo`
- implement driver-manager friendly packaging

## Later Smoke Scenarios

- connect and run a simple Arrow-native query
- export a result stream without row materialization
- bind Arrow batches for ingest
- inspect metadata and info surfaces

