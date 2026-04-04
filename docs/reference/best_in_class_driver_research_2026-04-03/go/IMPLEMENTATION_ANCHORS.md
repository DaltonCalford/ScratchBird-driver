# Go driver Implementation Anchors

Date: 2026-04-03
Lane: `go`
Selected benchmark: `pgx`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/golang/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `pgx docs`: https://pkg.go.dev/github.com/jackc/pgx/v5
- `pgx repo`: https://github.com/jackc/pgx (`refs/heads/master 08c9bb1f0d8fa6cc10ed8c713e68b1baa64dfe2c`)
- `go-sql-driver/mysql repo`: https://github.com/go-sql-driver/mysql (`refs/heads/master fed2c72bc5183941d1907934a52d7fbf513b2ced`)
- `go-mssqldb repo`: https://github.com/microsoft/go-mssqldb (`refs/heads/main 17636aa5108e0c334caaf2008813e4860188dc5b`)

## Primary Competitive Closure Areas

- Strengthen benchmark-backed evidence for high-concurrency and large-result performance.
- Refine documentation around pooling, cancellation, and advanced codecs to exceed pgx
usability.
- Broaden ecosystem guidance for ORMs and migration tools.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
