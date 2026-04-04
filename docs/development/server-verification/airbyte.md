# Airbyte Connector Server Verification Packet

Status: server_blocked

## Scope

- lane: `airbyte`
- benchmark: `Airbyte PostgreSQL source/destination`
- current state: `planned_beta1`
- planned track root: `tracks/beta/integrations/scratchbird-airbyte`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/airbyte/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_AIRBYTE_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Airbyte runtime matrix
- connector runtime assets produced by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/integrations/scratchbird-airbyte`
2. `./bin/bootstrap`

## Verification Commands

1. contract/conformance: `./bin/test-contract`
2. performance: `./bin/test-perf`

## Expected Artifacts

- `release/readiness/airbyte/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/airbyte/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/airbyte/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/airbyte/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/airbyte/<version>/KNOWN_GAPS.md`
- `release/readiness/airbyte/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/airbyte/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every compatibility family from `docs/application-reference/AIRBYTE_CONNECTOR_COMPATIBILITY_SPECIFICATION.md` is implemented and proven
- source and destination connector behavior are proven rather than assumed
- all release evidence is staged under `release/readiness/airbyte/<version>/`

