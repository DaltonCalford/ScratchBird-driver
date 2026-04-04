# Julia Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `LibPQ.jl`
- Authoritative lane spec: `docs/specifications/drivers/JULIA_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/julia/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_JULIA_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the package, examples, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/drivers/julia`

## Planned Package Identity

- Julia package for ScratchBird connectivity
- release evidence path: `release/readiness/julia/<version>/`

## First Implementation Focus

- implement `DBInterface` bootstrap and connection handling
- implement query/prepare/bind/fetch
- implement `Tables.jl` / `DataFrames.jl` shaping
- implement transaction and copy flows

## Later Smoke Scenarios

- open connection and run simple query
- return rows into `DataFrames.jl`
- execute prepared statement with binds
- commit and rollback a transaction

