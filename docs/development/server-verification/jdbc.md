# JDBC Server Verification Packet

Status: server_blocked

## Scope

- lane: `jdbc`
- benchmark: `pgjdbc`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/jdbc`

## Required Environment

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
- `SCRATCHBIRD_JDBC_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/jdbc`

## Verification Commands

1. `./gradlew test`

## Expected Artifacts

- `release/readiness/jdbc/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/jdbc/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/jdbc/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/jdbc/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/jdbc/<version>/KNOWN_GAPS.md`
- `release/readiness/jdbc/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/jdbc/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/jdbc/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
