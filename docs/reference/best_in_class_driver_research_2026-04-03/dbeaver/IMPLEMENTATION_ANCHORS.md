# DBeaver integration Implementation Anchors

Date: 2026-04-03
Lane: `dbeaver`
Selected benchmark: `DBeaver PostgreSQL extension`

## ScratchBird Current Truth Inputs

Current truth sources: README.md;
docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `DBeaver driver docs`: https://dbeaver.com/docs/dbeaver/Database-drivers/
- `DBeaver PostgreSQL plugin`: https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.postgresql
- `DBeaver MySQL plugin`: https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.mysql
- `DBeaver SQL Server plugin`: https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.mssql

## Primary Competitive Closure Areas

- Expand navigator and schema-tree behavior to match the first-party DBeaver extensions
without resorting to manual toggles.
- Add explain/plan, DDL editor, and richer metadata view integration.
- Harden stock-install and update-site packaging/documentation for enterprise installs.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
