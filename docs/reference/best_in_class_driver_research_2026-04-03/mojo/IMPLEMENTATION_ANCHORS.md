# Mojo driver Implementation Anchors

Date: 2026-04-03
Lane: `mojo`
Selected benchmark: `Composite (asyncpg + pgx + PostgresNIO)`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/DRIVER_MOJO_NATIVE_API.md; docs/planning/driver-checklists/mojo.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `asyncpg docs`: https://magicstack.github.io/asyncpg/current/
- `asyncpg repo`: https://github.com/MagicStack/asyncpg (`refs/heads/master db8ecc2a38e16fb0c090aef6f5506547c2831c24`)
- `pgx docs`: https://pkg.go.dev/github.com/jackc/pgx/v5
- `PostgresNIO repo`: https://github.com/vapor/postgres-nio (`refs/heads/main f294b6205defeb23dc04c4e094b04f0de5784d4b`)

## Primary Competitive Closure Areas

- Replace the Python bridge with a native transport/runtime path.
- Close native TLS, streaming, type-wrapper, and packaging gaps using the composite
benchmark as the target bar.
- Add first-class examples and performance proof once the transport cutover lands.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
