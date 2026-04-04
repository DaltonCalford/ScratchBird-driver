# .NET driver Implementation Anchors

Date: 2026-04-03
Lane: `dotnet`
Selected benchmark: `Npgsql`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/dotnet-csharp/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `Npgsql docs`: https://www.npgsql.org/doc/index.html
- `Npgsql repo`: https://github.com/npgsql/npgsql (`refs/heads/main 3698a477b3f52808e3c4ecf9ba53e3db8c8b6e5c`)
- `Microsoft.Data.SqlClient docs`: https://learn.microsoft.com/en-us/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace?view=sql-server-ver17
- `MySqlConnector repo`: https://github.com/mysql-net/MySqlConnector (`refs/heads/master 060488be2f1109ae18f40ad93821245fe1e7611d`)

## Primary Competitive Closure Areas

- Publish benchmark and operational evidence at the same standard expected of top-tier
ADO.NET providers.
- Tighten integration guidance for ORMs, diagnostics, and pooling scenarios.
- Surface advanced provider ergonomics and troubleshooting guidance more directly in docs.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
