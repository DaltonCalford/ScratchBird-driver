# Hibernate Dialect Server Verification Packet

Status: server_blocked

## Scope

- lane: `hibernate`
- benchmark: `Hibernate PostgreSQLDialect`
- current state: `partial_contract_only`
- track root: `tracks/alpha/integrations/scratchbird-hibernate-dialect`

## Required Environment

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

## Build / Bootstrap Commands

1. `cd tracks/alpha/integrations/scratchbird-hibernate-dialect`

## Verification Commands

1. `mvn test`

## Expected Artifacts

- `release/readiness/hibernate/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/hibernate/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/hibernate/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/hibernate/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/hibernate/<version>/KNOWN_GAPS.md`
- `release/readiness/hibernate/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/hibernate/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/hibernate/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
