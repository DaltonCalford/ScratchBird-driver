# Dart driver Implementation Anchors

Date: 2026-04-03
Lane: `dart`
Selected benchmark: `postgres (Dart)`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/DRIVER_DART_DATABASE_API.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `pub.dev postgres`: https://pub.dev/packages/postgres
- `postgresql-dart repo`: https://github.com/isoos/postgresql-dart (`refs/heads/master 43345da8f52f15a395c215ca593920b144f5ad25`)
- `mysql1 package`: https://pub.dev/packages/mysql1
- `sqlite3 package`: https://pub.dev/packages/sqlite3

## Primary Competitive Closure Areas

- Complete transaction failure-path, suspend/resume, and resilience proof to the level
expected by the leading Dart driver.
- Fill metadata restriction and DDL payload coverage gaps for tooling ecosystems.
- Broaden live complex-type codecs and runtime SQLSTATE/error propagation proof.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
