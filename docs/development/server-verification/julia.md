# Julia Driver Server Verification Packet

Status: server_blocked

## Scope

- lane: `julia`
- benchmark: `LibPQ.jl`
- current state: `planned_beta1`
- planned track root: `tracks/beta/drivers/julia`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/julia/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_JULIA_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Julia runtime
- package test dependencies required by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/drivers/julia`
2. `julia --project=. -e 'using Pkg; Pkg.instantiate()'`

## Verification Commands

1. contract/conformance: `julia --project=. -e 'using Pkg; Pkg.test()'`
2. performance: `julia --project=. benchmarks/run.jl`

## Expected Artifacts

- `release/readiness/julia/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/julia/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/julia/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/julia/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/julia/<version>/KNOWN_GAPS.md`
- `release/readiness/julia/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/julia/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every capability family from `docs/specifications/drivers/JULIA_DRIVER_SPECIFICATION.md` is implemented and proven
- `DBInterface` and `DataFrames.jl` shaping behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/julia/<version>/`

