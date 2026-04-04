# JDBC driver Implementation Anchors

Date: 2026-04-03
Lane: `jdbc`
Selected benchmark: `pgjdbc`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md;
docs/specifications/drivers/language/java-jdbc/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `pgjdbc docs`: https://jdbc.postgresql.org/documentation/
- `pgjdbc repo`: https://github.com/pgjdbc/pgjdbc (`refs/heads/master 99f6c0ebebe17a4788602e39d65010cbab0ca658`)
- `Connector/J repo`: https://github.com/mysql/mysql-connector-j (`refs/heads/release/9.x fdef61f4af21fa9e0ac334ff0664ec754c164cc0`)
- `Microsoft JDBC docs`: https://learn.microsoft.com/en-us/sql/connect/jdbc/overview-of-the-jdbc-driver?view=sql-server-ver17
- `mssql-jdbc repo`: https://github.com/microsoft/mssql-jdbc (`refs/heads/main e8d39f3907dd80c36732ade6730bda3b6de2e1ab`)

## Primary Competitive Closure Areas

- Benchmark and publish metadata breadth, large-object, batch, and performance evidence at
pgjdbc quality.
- Tighten framework-facing guidance for Hibernate, Spring, BI tooling, and migration
ecosystems.
- Raise packaging/release cadence documentation to the standard of major JDBC providers.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
