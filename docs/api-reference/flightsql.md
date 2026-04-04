# Flight SQL Driver API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Apache Arrow Flight SQL client stack`
- Authoritative lane spec: `docs/specifications/drivers/FLIGHT_SQL_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/flightsql/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_FLIGHTSQL_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the Flight SQL transport and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- native Flight SQL client package/runtime
- Arrow stream integration surface
- release evidence root: `release/readiness/flightsql/<version>/`

## Mandatory API Surface

- session/bootstrap and auth/channel configuration
- query and prepared-statement lifecycle
- Arrow stream and partition/ticket handling
- metadata and cancellation operations

## Non-Optional Behaviors

- analytical transport must be native, not a JDBC bridge
- metadata and diagnostics must remain predictable across the protocol mapping
- result streaming must preserve MGA/session correctness

## Later Proof

- server verification packet: `docs/development/server-verification/flightsql.md`
- release evidence root: `release/readiness/flightsql/<version>/`

