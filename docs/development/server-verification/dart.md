# Dart Server Verification Packet

Status: server_blocked

## Scope

- lane: `dart`
- benchmark: `postgres (Dart)`
- current state: `partial`
- track root: `tracks/p3/drivers/dart`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/dart`
2. `dart pub get`

## Verification Commands

1. `dart test`

## Expected Artifacts

- `release/readiness/dart/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/dart/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/dart/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/dart/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/dart/<version>/KNOWN_GAPS.md`
- `release/readiness/dart/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/dart/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/dart/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
