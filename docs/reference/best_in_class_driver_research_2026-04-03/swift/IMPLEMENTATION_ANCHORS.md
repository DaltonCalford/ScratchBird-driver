# Swift driver Implementation Anchors

Date: 2026-04-03
Lane: `swift`
Selected benchmark: `PostgresNIO`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `PostgresNIO repo`: https://github.com/vapor/postgres-nio (`refs/heads/main f294b6205defeb23dc04c4e094b04f0de5784d4b`)
- `PostgresKit repo`: https://github.com/vapor/postgres-kit (`refs/heads/main 7c079553e9cda74811e627775bf22e40a9405ad9`)
- `MySQLNIO repo`: https://github.com/vapor/mysql-nio (`refs/heads/main 7fa853040169b604a16b963f23b481772f4ac181`)

## Primary Competitive Closure Areas

- Close live cancellation, suspend/resume, metadata, codec, and pool recovery gaps.
- Improve async/await and NIO lifecycle documentation and examples.
- Publish performance and reliability evidence expected in modern Swift server stacks.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
