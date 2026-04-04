# ODBC driver Implementation Anchors

Date: 2026-04-03
Lane: `odbc`
Selected benchmark: `Microsoft ODBC Driver for SQL Server`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `Microsoft ODBC docs`: https://learn.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server
- `psqlODBC project`: https://odbc.postgresql.org/
- `psqlODBC repo`: https://github.com/postgresql-interfaces/psqlodbc (`refs/heads/main 863a0e938dd50c7b68208484bdc3ef8b00735a92`)
- `MySQL Connector/ODBC repo`: https://github.com/mysql/mysql-connector-odbc (`refs/heads/trunk 48709cc9393225aa768e32219eb66292815f489b`)

## Primary Competitive Closure Areas

- Close full-family metadata and catalog-surface gaps against the strongest ODBC drivers.
- Broaden descriptor, cursor, and diagnostics coverage where the commercial benchmark is
stronger.
- Improve platform packaging and installation guidance across Windows and Linux.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
