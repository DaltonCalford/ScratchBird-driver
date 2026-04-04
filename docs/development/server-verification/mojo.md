# Mojo Server Verification Packet

Status: server_blocked

## Scope

- lane: `mojo`
- benchmark: `Composite (asyncpg + pgx + PostgresNIO)`
- current state: `hybrid_native_gap`
- track root: `tracks/p3/drivers/mojo`

## Required Environment

- `SCRATCHBIRD_MOJO_URL`
- `MOJO_ENABLED`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/mojo/tests`

## Verification Commands

1. `mojo integration.mojo`

## Expected Artifacts

- `release/readiness/mojo/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/mojo/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/mojo/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/mojo/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/mojo/<version>/KNOWN_GAPS.md`
- `release/readiness/mojo/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/mojo/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/mojo/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
