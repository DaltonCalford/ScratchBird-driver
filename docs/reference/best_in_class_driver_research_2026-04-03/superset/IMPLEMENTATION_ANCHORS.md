# Superset adapter Implementation Anchors

Date: 2026-04-03
Lane: `superset`
Selected benchmark: `Superset PostgreSQL engine spec`

## ScratchBird Current Truth Inputs

Current truth sources: README.md; docs/application-
reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md; docs/api-reference/superset.md;
docs/getting-started/superset.md; docs/planning/driver-checklists/superset.md;
tracks/alpha/integrations/scratchbird-sqlalchemy-dialect/README.md

## Benchmark/Reference Anchors

- `Superset DB engine specs`: https://github.com/apache/superset/tree/master/superset/db_engine_specs
- `Superset repo`: https://github.com/apache/superset (`refs/heads/master d796543f5a0c5f6306f3140d48647640b7a28a14`)
- `Superset repo`: https://github.com/apache/superset (`refs/heads/master d796543f5a0c5f6306f3140d48647640b7a28a14`)

## Primary Competitive Closure Areas

- Expand engine-spec capability flags, time grains, and SQL Lab behavior to match first-
party backends.
- Add end-to-end dataset discovery, async query, and dashboard validation.
- Harden package/install guidance for real Superset deployments.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
