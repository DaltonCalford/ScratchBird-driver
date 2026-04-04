# Node.js / TypeScript Server Verification Packet

Status: server_blocked

## Scope

- lane: `node`
- benchmark: `node-postgres`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/node`

## Required Environment

- `SCRATCHBIRD_NODE_URL`
- `SCRATCHBIRD_NODE_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/node`
2. `npm install`

## Verification Commands

1. `npm test`

## Expected Artifacts

- `release/readiness/node/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/node/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/node/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/node/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/node/<version>/KNOWN_GAPS.md`
- `release/readiness/node/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/node/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/node/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
