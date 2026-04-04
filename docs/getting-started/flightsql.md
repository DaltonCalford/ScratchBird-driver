# Flight SQL Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Apache Arrow Flight SQL client stack`
- Authoritative lane spec: `docs/specifications/drivers/FLIGHT_SQL_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/flightsql/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_FLIGHTSQL_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the transport, package artifacts, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/drivers/flightsql`

## Planned Package Identity

- native Flight SQL client/runtime package
- release evidence path: `release/readiness/flightsql/<version>/`

## First Implementation Focus

- land session/auth bootstrap
- land query and prepared statement lifecycle
- land Arrow stream and partition support
- land metadata and cancellation support

## Later Smoke Scenarios

- execute a simple query over Flight SQL
- prepare/bind/execute a statement
- stream a large Arrow result
- cancel a running operation

