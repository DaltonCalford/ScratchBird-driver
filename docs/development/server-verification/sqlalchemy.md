# SQLAlchemy Dialect Server Verification Packet

Status: server_blocked

## Scope

- lane: `sqlalchemy`
- benchmark: `SQLAlchemy PostgreSQL dialect`
- current state: `partial_adapter`
- track root: `tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`

## Build / Bootstrap Commands

1. `cd tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`
2. `python -m pip install -e ".[tooling]"`

## Verification Commands

1. `python -m pytest`

## Expected Artifacts

- `release/readiness/sqlalchemy/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/sqlalchemy/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/sqlalchemy/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/sqlalchemy/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/sqlalchemy/<version>/KNOWN_GAPS.md`
- `release/readiness/sqlalchemy/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/sqlalchemy/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/sqlalchemy/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
