# Rust driver Implementation Anchors

Date: 2026-04-03
Lane: `rust`
Selected benchmark: `tokio-postgres`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/rust/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `tokio-postgres docs`: https://docs.rs/tokio-postgres/latest/tokio_postgres/
- `rust-postgres repo`: https://github.com/sfackler/rust-postgres (`refs/heads/master 6e6a627832313cbd92bbf383c74dac1cd7064cb0`)
- `sqlx docs`: https://docs.rs/sqlx/latest/sqlx/
- `mysql_async docs`: https://docs.rs/mysql_async/latest/mysql_async/

## Primary Competitive Closure Areas

- Publish benchmark and concurrency evidence at the standard of the leading Rust async
drivers.
- Expand framework, migration, and ecosystem integration guidance.
- Broaden observability and troubleshooting examples for async workloads.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
