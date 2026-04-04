# ODBC Server Verification Packet

Status: server_blocked

## Scope

- lane: `odbc`
- benchmark: `Microsoft ODBC Driver for SQL Server`
- current state: `partial`
- track root: `tracks/p3/drivers/odbc`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`

## Build / Bootstrap Commands

1. `cmake -S tracks/p3/drivers/odbc -B build/odbc-runtime -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON`
2. `cmake --build build/odbc-runtime --config Release`

## Verification Commands

1. `ctest --test-dir build/odbc-runtime --output-on-failure -R '^scratchbird_odbc_tests$'`

## Expected Artifacts

- `release/readiness/odbc/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/odbc/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/odbc/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/odbc/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/odbc/<version>/KNOWN_GAPS.md`
- `release/readiness/odbc/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/odbc/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/odbc/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
