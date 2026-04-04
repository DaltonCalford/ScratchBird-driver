# Rust Server Verification Packet

Status: server_blocked

## Scope

- lane: `rust`
- benchmark: `tokio-postgres`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/rust`

## Required Environment

- `SCRATCHBIRD_RUST_URL`
- `SCRATCHBIRD_RUST_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/rust`
2. `cargo build`

## Verification Commands

1. `cargo test`

## Expected Artifacts

- `release/readiness/rust/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/rust/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/rust/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/rust/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/rust/<version>/KNOWN_GAPS.md`
- `release/readiness/rust/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/rust/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/rust/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
