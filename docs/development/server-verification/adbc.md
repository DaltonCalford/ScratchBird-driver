# ADBC / Arrow Driver Server Verification Packet

Status: server_blocked

## Scope

- lane: `adbc`
- benchmark: `Apache Arrow ADBC PostgreSQL driver`
- current state: `planned_beta1`
- planned track root: `tracks/beta/drivers/adbc`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/adbc/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_ADBC_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- C/C++ build environment with CMake
- Arrow/ADBC test prerequisites required by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/drivers/adbc`
2. `cmake -S . -B build && cmake --build build`

## Verification Commands

1. contract/conformance: `ctest --test-dir build --output-on-failure`
2. performance: `ctest --test-dir build -R perf --output-on-failure`

## Expected Artifacts

- `release/readiness/adbc/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/adbc/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/adbc/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/adbc/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/adbc/<version>/KNOWN_GAPS.md`
- `release/readiness/adbc/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/adbc/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every capability family from `docs/specifications/drivers/ADBC_DRIVER_SPECIFICATION.md` is implemented and proven
- Arrow import/export and metadata behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/adbc/<version>/`

