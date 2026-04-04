# CLI Tooling Server Verification Packet

Status: server_blocked

## Scope

- lane: `cli`
- benchmark: `psql`
- current state: `tooling_partial`
- track root: `tracks/p3/drivers/cli`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF`
2. `cmake --build build_cli --config Release`

## Verification Commands

1. `ctest --test-dir build_cli --output-on-failure`
2. `build_cli/sbdriver_conformance --help`

## Expected Artifacts

- `release/readiness/cli/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/cli/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/cli/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/cli/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/cli/<version>/KNOWN_GAPS.md`
- `release/readiness/cli/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/cli/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/cli/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
