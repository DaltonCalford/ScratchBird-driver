# Python driver Implementation Anchors

Date: 2026-04-03
Lane: `python`
Selected benchmark: `psycopg3`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/python/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `psycopg3 docs`: https://www.psycopg.org/psycopg3/docs/
- `psycopg repo`: https://github.com/psycopg/psycopg (`refs/heads/master eaeb5edeb1f08c6930d5598237136fbe167e0317`)
- `asyncpg docs`: https://magicstack.github.io/asyncpg/current/
- `mysqlclient repo`: https://github.com/PyMySQL/mysqlclient (`refs/heads/main a417303a0597113d2299f63c04f9055e09950ee1`)

## Primary Competitive Closure Areas

- Publish benchmark and async/runtime evidence at the standard expected by top Python
drivers.
- Broaden packaging and framework integration guidance beyond baseline usage.
- Strengthen documentation for advanced codecs, cancellation, and copy/stream patterns.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
