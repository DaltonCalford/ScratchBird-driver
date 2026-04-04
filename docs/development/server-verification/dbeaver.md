# DBeaver Extension Server Verification Packet

Status: server_blocked

## Scope

- lane: `dbeaver`
- benchmark: `DBeaver PostgreSQL extension`
- current state: `partial_plugin`
- track root: `tracks/alpha/integrations/scratchbird-dbeaver-driver`

## Required Environment

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

## Build / Bootstrap Commands

1. `cd tracks/alpha/integrations/scratchbird-dbeaver-driver`
2. `mvn test`

## Verification Commands

1. `mvn -pl test/org.jkiss.dbeaver.ext.scratchbird.test test`

## Expected Artifacts

- `release/readiness/dbeaver/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/dbeaver/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/dbeaver/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/dbeaver/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/dbeaver/<version>/KNOWN_GAPS.md`
- `release/readiness/dbeaver/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/dbeaver/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/dbeaver/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
