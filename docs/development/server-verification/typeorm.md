# TypeORM Adapter Server Verification Packet

Status: server_blocked

## Scope

- lane: `typeorm`
- benchmark: `TypeORM PostgreSQL driver`
- current state: `partial_contract_only`
- track root: `tracks/alpha/integrations/scratchbird-typeorm-adapter`

## Required Environment

- `DATABASE_URL`

## Build / Bootstrap Commands

1. `cd tracks/alpha/integrations/scratchbird-typeorm-adapter`
2. `npm install`

## Verification Commands

1. `npm test`

## Expected Artifacts

- `release/readiness/typeorm/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/typeorm/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/typeorm/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/typeorm/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/typeorm/<version>/KNOWN_GAPS.md`
- `release/readiness/typeorm/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/typeorm/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/typeorm/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
