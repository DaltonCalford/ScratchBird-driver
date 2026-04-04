# Flight SQL Driver Server Verification Packet

Status: server_blocked

## Scope

- lane: `flightsql`
- benchmark: `Apache Arrow Flight SQL client stack`
- current state: `planned_beta1`
- planned track root: `tracks/beta/drivers/flightsql`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/flightsql/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_FLIGHTSQL_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- C/C++ build environment with CMake
- Arrow/Flight runtime dependencies required by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/drivers/flightsql`
2. `cmake -S . -B build && cmake --build build`

## Verification Commands

1. contract/conformance: `ctest --test-dir build --output-on-failure`
2. performance: `ctest --test-dir build -R perf --output-on-failure`

## Expected Artifacts

- `release/readiness/flightsql/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/flightsql/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/flightsql/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/flightsql/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/flightsql/<version>/KNOWN_GAPS.md`
- `release/readiness/flightsql/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/flightsql/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every capability family from `docs/specifications/drivers/FLIGHT_SQL_DRIVER_SPECIFICATION.md` is implemented and proven
- Arrow stream and metadata behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/flightsql/<version>/`

