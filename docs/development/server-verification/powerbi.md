# Power BI Connector Server Verification Packet

Status: server_blocked

## Scope

- lane: `powerbi`
- benchmark: `Power BI PostgreSQL / ODBC custom connector surface`
- current state: `planned_beta1`
- planned track root: `tracks/beta/integrations/scratchbird-powerbi`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/powerbi/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_POWERBI_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Power BI Desktop/gateway matrix
- connector packaging assets produced by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/integrations/scratchbird-powerbi`
2. `./bin/bootstrap`

## Verification Commands

1. contract/conformance: `./bin/test-contract`
2. performance: `./bin/test-perf`

## Expected Artifacts

- `release/readiness/powerbi/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/powerbi/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/powerbi/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/powerbi/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/powerbi/<version>/KNOWN_GAPS.md`
- `release/readiness/powerbi/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/powerbi/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every compatibility family from `docs/application-reference/POWERBI_COMPATIBILITY_SPECIFICATION.md` is implemented and proven
- connector install, import, refresh, and diagnostics behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/powerbi/<version>/`

