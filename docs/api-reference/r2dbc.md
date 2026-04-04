# R2DBC Driver API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `PostgreSQL R2DBC driver`
- Authoritative lane spec: `docs/specifications/drivers/R2DBC_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/r2dbc/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_R2DBC_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but transport/client code and all live proof are still outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- Maven/Gradle coordinates for the native driver
- `ConnectionFactoryProvider` registration
- Spring Data R2DBC and `r2dbc-pool` compatibility hooks

## Mandatory API Surface

- `ConnectionFactory` lifecycle and option parsing
- reactive `Connection`, `Statement`, `Batch`, and `Result`
- bind markers, generated values, and batch execution
- transaction and savepoint control
- row metadata, parameter metadata, and error mapping

## Non-Optional Behaviors

- deterministic backpressure handling
- deterministic cancel/timeout mapping
- MGA-safe reconnect and transaction-state rules
- metadata/type fidelity not weaker than the JDBC/.NET baseline for equivalent families

## Later Proof

- server verification packet: `docs/development/server-verification/r2dbc.md`
- release evidence root: `release/readiness/r2dbc/<version>/`

