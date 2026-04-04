# Superset Driver Server Verification Packet

Status: server_blocked

## Scope

- lane: `superset`
- benchmark: `Superset PostgreSQL engine spec`
- current state: `partial_adapter`
- track root: `tracks/beta/integrations/scratchbird-superset-driver`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`

## Build / Bootstrap Commands

1. `cd tracks/beta/integrations/scratchbird-superset-driver`
2. `python -m pip install -e ".[tooling,superset]"`

## Verification Commands

1. `python -m pytest`

## Expected Artifacts

- `release/readiness/superset/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/superset/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/superset/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/superset/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/superset/<version>/KNOWN_GAPS.md`
- `release/readiness/superset/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/superset/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/superset/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
