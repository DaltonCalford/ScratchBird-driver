# C/C++ Server Verification Packet

Status: server_blocked

## Scope

- lane: `cpp`
- benchmark: `libpqxx`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/cpp`

## Required Environment

- `SCRATCHBIRD_CPP_URL`
- `SCRATCHBIRD_CPP_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cmake -S tracks/p3/drivers/cpp -B build-cpp -DCMAKE_BUILD_TYPE=Release`
2. `cmake --build build-cpp --config Release`

## Verification Commands

1. `ctest --test-dir build-cpp --output-on-failure`
2. `scratchbird_client_tests`

## Expected Artifacts

- `release/readiness/cpp/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/cpp/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/cpp/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/cpp/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/cpp/<version>/KNOWN_GAPS.md`
- `release/readiness/cpp/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/cpp/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/cpp/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
