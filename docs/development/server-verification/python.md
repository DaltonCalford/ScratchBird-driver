# Python Server Verification Packet

Status: server_blocked

## Scope

- lane: `python`
- benchmark: `psycopg3`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/python`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/python`
2. `python -m pip install --upgrade pip`
3. `python -m pip install -e ".[test]"`

## Verification Commands

1. `python -m pytest`

## Expected Artifacts

- `release/readiness/python/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/python/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/python/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/python/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/python/<version>/KNOWN_GAPS.md`
- `release/readiness/python/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/python/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/python/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
