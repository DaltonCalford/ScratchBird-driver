# Metabase Plugin Server Verification Packet

Status: server_blocked

## Scope

- lane: `metabase`
- benchmark: `Metabase PostgreSQL driver`
- current state: `partial_adapter`
- track root: `tracks/alpha/integrations/scratchbird-metabase-driver`

## Required Environment

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

## Build / Bootstrap Commands

1. `cd tracks/alpha/integrations/scratchbird-metabase-driver`

## Verification Commands

1. `clojure -M:test`

## Expected Artifacts

- `release/readiness/metabase/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/metabase/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/metabase/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/metabase/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/metabase/<version>/KNOWN_GAPS.md`
- `release/readiness/metabase/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/metabase/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/metabase/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
