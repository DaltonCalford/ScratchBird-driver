# R2DBC Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `PostgreSQL R2DBC driver`
- Authoritative lane spec: `docs/specifications/drivers/R2DBC_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/r2dbc/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_R2DBC_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the driver and live validation artifacts do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/drivers/r2dbc`

## Planned Package Identity

- native R2DBC driver package for JVM consumers
- release evidence path: `release/readiness/r2dbc/<version>/`

## First Implementation Focus

- bootstrap a native `ConnectionFactory` and auth/TLS option parser
- land reactive statement, bind, transaction, and result-streaming flows
- land metadata and SQLSTATE/error mapping parity
- add Spring Data and pooling smoke examples

## Later Smoke Scenarios

- open connection and run simple query
- prepare/bind/execute with generated values
- transaction plus savepoint round-trip
- stream a large result with cancellation

