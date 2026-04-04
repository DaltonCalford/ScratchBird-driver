# Swift Server Verification Packet

Status: server_blocked

## Scope

- lane: `swift`
- benchmark: `PostgresNIO`
- current state: `partial`
- track root: `tracks/p3/drivers/swift`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/swift`
2. `swift build`

## Verification Commands

1. `swift test`

## Expected Artifacts

- `release/readiness/swift/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/swift/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/swift/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/swift/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/swift/<version>/KNOWN_GAPS.md`
- `release/readiness/swift/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/swift/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/swift/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
