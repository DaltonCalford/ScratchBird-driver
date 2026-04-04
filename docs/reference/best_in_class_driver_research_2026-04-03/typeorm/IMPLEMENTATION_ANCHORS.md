# TypeORM adapter Implementation Anchors

Date: 2026-04-03
Lane: `typeorm`
Selected benchmark: `TypeORM PostgreSQL driver`

## ScratchBird Current Truth Inputs

Current truth sources: README.md; examples/README.md; tracks/p3/drivers/node/README.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `TypeORM PostgreSQL docs`: https://typeorm.io/docs/drivers/postgres/
- `TypeORM repo`: https://github.com/typeorm/typeorm (`refs/heads/master e8b7f50a260f77107c8e107507479876a84beaaa`)
- `TypeORM MySQL docs`: https://typeorm.io/docs/drivers/mysql/
- `TypeORM SQL Server docs`: https://typeorm.io/docs/drivers/microsoft-sqlserver/

## Primary Competitive Closure Areas

- Move from deterministic scaffolding to a full datasource, schema sync, migration, and
relation-loading surface.
- Close metadata reflection and query-builder behavior gaps.
- Add installation, packaging, and framework validation evidence.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
