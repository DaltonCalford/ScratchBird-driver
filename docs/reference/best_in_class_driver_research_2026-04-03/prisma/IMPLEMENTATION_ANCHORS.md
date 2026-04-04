# Prisma adapter Implementation Anchors

Date: 2026-04-03
Lane: `prisma`
Selected benchmark: `Prisma PostgreSQL connector`

## ScratchBird Current Truth Inputs

Current truth sources: README.md; docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md;
tracks/p3/drivers/node/README.md

## Benchmark/Reference Anchors

- `Prisma PostgreSQL docs`: https://www.prisma.io/docs/orm/overview/databases/postgresql
- `Prisma repo`: https://github.com/prisma/prisma (`refs/heads/main ada077ba32b5801d00d32f1434a45aaae7bc09a9`)
- `Prisma MySQL docs`: https://www.prisma.io/docs/orm/overview/databases/mysql
- `Prisma SQL Server docs`: https://www.prisma.io/docs/orm/overview/databases/sql-server

## Primary Competitive Closure Areas

- Move from deterministic helper scaffolding to a full provider-quality introspection and
migration surface.
- Close datasource validation, schema reflection, and transaction/runtime behavior gaps.
- Add packaging and framework-facing integration guidance for Prisma users.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
