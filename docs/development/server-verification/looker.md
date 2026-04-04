# Looker Connector Server Verification Packet

Status: server_blocked

## Scope

- lane: `looker`
- benchmark: `Looker PostgreSQL dialect`
- current state: `planned_beta1`
- planned track root: `tracks/beta/integrations/scratchbird-looker`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/looker/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_LOOKER_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Looker runtime matrix
- deployment assets produced by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/integrations/scratchbird-looker`
2. `./bin/bootstrap`

## Verification Commands

1. contract/conformance: `./bin/test-contract`
2. performance: `./bin/test-perf`

## Expected Artifacts

- `release/readiness/looker/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/looker/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/looker/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/looker/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/looker/<version>/KNOWN_GAPS.md`
- `release/readiness/looker/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/looker/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every compatibility family from `docs/application-reference/LOOKER_COMPATIBILITY_SPECIFICATION.md` is implemented and proven
- dialect, SQL Runner, explore, and PDT behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/looker/<version>/`

