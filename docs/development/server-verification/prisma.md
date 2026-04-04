# Prisma Adapter Server Verification Packet

Status: server_blocked

## Scope

- lane: `prisma`
- benchmark: `Prisma PostgreSQL connector`
- current state: `partial_contract_only`
- track root: `tracks/alpha/integrations/scratchbird-prisma-adapter`

## Required Environment

- `DATABASE_URL`

## Build / Bootstrap Commands

1. `cd tracks/alpha/integrations/scratchbird-prisma-adapter`
2. `npm install`

## Verification Commands

1. `npm test`

## Expected Artifacts

- `release/readiness/prisma/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/prisma/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/prisma/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/prisma/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/prisma/<version>/KNOWN_GAPS.md`
- `release/readiness/prisma/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/prisma/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/prisma/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
