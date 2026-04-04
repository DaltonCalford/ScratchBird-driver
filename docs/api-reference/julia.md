# Julia Driver API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `LibPQ.jl`
- Authoritative lane spec: `docs/specifications/drivers/JULIA_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/julia/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_JULIA_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the Julia package and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- Julia package for ScratchBird connectivity
- `DBInterface` integration
- `Tables.jl` / `DataFrames.jl` shaping support

## Mandatory API Surface

- connect/prepare/execute/fetch helpers
- typed bind and result conversion
- transaction and copy/import-export operations
- metadata and diagnostic surfaces expected by Julia users

## Non-Optional Behaviors

- deterministic null/type mapping
- `DataFrames.jl`-friendly result shaping
- error and transaction behavior not weaker than mainstream Julia DB drivers

## Later Proof

- server verification packet: `docs/development/server-verification/julia.md`
- release evidence root: `release/readiness/julia/<version>/`

