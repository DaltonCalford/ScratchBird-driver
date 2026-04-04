# Go Server Verification Packet

Status: server_blocked

## Scope

- lane: `go`
- benchmark: `pgx`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/go`

## Required Environment

- `SCRATCHBIRD_GO_URL`
- `SCRATCHBIRD_GO_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/go`

## Verification Commands

1. `go test ./...`

## Expected Artifacts

- `release/readiness/go/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/go/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/go/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/go/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/go/<version>/KNOWN_GAPS.md`
- `release/readiness/go/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/go/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/go/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
