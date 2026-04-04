# dbt Adapter Server Verification Packet

Status: server_blocked

## Scope

- lane: `dbt`
- benchmark: `dbt-postgres`
- current state: `planned_beta1`
- planned track root: `tracks/beta/integrations/scratchbird-dbt-adapter`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/dbt/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_DBT_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Python/dbt-core runtime matrix
- example dbt project and profile under the lane root

## Build / Bootstrap Commands

1. `cd tracks/beta/integrations/scratchbird-dbt-adapter`
2. `./bin/bootstrap`

## Verification Commands

1. contract/conformance: `./bin/test-contract`
2. performance: `./bin/test-perf`

## Expected Artifacts

- `release/readiness/dbt/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/dbt/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/dbt/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/dbt/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/dbt/<version>/KNOWN_GAPS.md`
- `release/readiness/dbt/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/dbt/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every compatibility family from `docs/application-reference/DBT_ADAPTER_COMPATIBILITY_SPECIFICATION.md` is implemented and proven
- adapter workflows for run/test/docs/snapshot are proven rather than assumed
- all release evidence is staged under `release/readiness/dbt/<version>/`

