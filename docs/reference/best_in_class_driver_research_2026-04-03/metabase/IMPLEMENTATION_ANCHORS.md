# Metabase adapter Implementation Anchors

Date: 2026-04-03
Lane: `metabase`
Selected benchmark: `Metabase PostgreSQL driver`

## ScratchBird Current Truth Inputs

Current truth sources: README.md; docs/application-
reference/METABASE_COMPATIBILITY_SPECIFICATION.md; docs/api-reference/metabase.md;
docs/getting-started/metabase.md; docs/planning/driver-checklists/metabase.md;
docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md

## Benchmark/Reference Anchors

- `Metabase databases docs`: https://www.metabase.com/docs/latest/databases/start
- `Metabase repo`: https://github.com/metabase/metabase (`refs/heads/master 672bd07e35ed7a70214c79fcd6b05668fb477f83`)
- `Metabase PostgreSQL docs`: https://www.metabase.com/docs/latest/databases/connections/postgresql
- `Metabase MySQL docs`: https://www.metabase.com/docs/latest/databases/connections/mysql
- `Metabase SQL Server docs`: https://www.metabase.com/docs/latest/databases/connections/sql-server

## Primary Competitive Closure Areas

- Close schema sync and field fingerprinting depth gaps so Metabase behavior matches the
leading first-party plugins.
- Harden capability flags, native query handling, and packaging/deployment guidance.
- Add full end-to-end plugin validation against modern Metabase runtimes.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
