# R2DBC Driver Server Verification Packet

Status: server_blocked

## Scope

- lane: `r2dbc`
- benchmark: `PostgreSQL R2DBC driver`
- current state: `planned_beta1`
- planned track root: `tracks/beta/drivers/r2dbc`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/r2dbc/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_R2DBC_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported JVM version for the lane
- a build environment capable of running `gradlew`

## Build / Bootstrap Commands

1. `cd tracks/beta/drivers/r2dbc`
2. `./gradlew clean testClasses`

## Verification Commands

1. contract/conformance: `./gradlew test`
2. performance: `./gradlew jmh`

## Expected Artifacts

- `release/readiness/r2dbc/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/r2dbc/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/r2dbc/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/r2dbc/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/r2dbc/<version>/KNOWN_GAPS.md`
- `release/readiness/r2dbc/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/r2dbc/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every capability family from `docs/specifications/drivers/R2DBC_DRIVER_SPECIFICATION.md` is implemented and proven
- Spring/pooling integration smoke tests pass
- cancellation and backpressure behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/r2dbc/<version>/`

