# R Server Verification Packet

Status: server_blocked

## Scope

- lane: `r`
- benchmark: `RPostgres`
- current state: `partial`
- track root: `tracks/p3/drivers/r`

## Required Environment

- `SCRATCHBIRD_R_URL`
- `SCRATCHBIRD_R_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/r`
2. `R CMD build .`

## Verification Commands

1. `R CMD check scratchbird_*.tar.gz`

## Expected Artifacts

- `release/readiness/r/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/r/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/r/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/r/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/r/<version>/KNOWN_GAPS.md`
- `release/readiness/r/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/r/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/r/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
