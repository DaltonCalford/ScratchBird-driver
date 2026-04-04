# Tableau Connector Server Verification Packet

Status: server_blocked

## Scope

- lane: `tableau`
- benchmark: `Tableau PostgreSQL / Named Connector SDK`
- current state: `planned_beta1`
- planned track root: `tracks/beta/integrations/scratchbird-tableau`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/tableau/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_TABLEAU_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Tableau runtime matrix
- connector packaging assets produced by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/integrations/scratchbird-tableau`
2. `./bin/bootstrap`

## Verification Commands

1. contract/conformance: `./bin/test-contract`
2. performance: `./bin/test-perf`

## Expected Artifacts

- `release/readiness/tableau/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/tableau/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/tableau/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/tableau/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/tableau/<version>/KNOWN_GAPS.md`
- `release/readiness/tableau/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/tableau/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every compatibility family from `docs/application-reference/TABLEAU_COMPATIBILITY_SPECIFICATION.md` is implemented and proven
- live query, extract, and metadata behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/tableau/<version>/`

