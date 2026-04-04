# Ruby driver Implementation Anchors

Date: 2026-04-03
Lane: `ruby`
Selected benchmark: `ruby-pg`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/ruby/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `ruby-pg repo`: https://github.com/ged/ruby-pg (`refs/heads/master 61f9b37fc02e5f36565737d25c415c1f26dfad68`)
- `mysql2 repo`: https://github.com/brianmario/mysql2 (`refs/heads/master b009d7e114729cbae5bef069a1033dd78acf7745`)
- `tiny_tds repo`: https://github.com/rails-sqlserver/tiny_tds (`refs/heads/master 1071d812b0e234a9d89628ba9da63dcd626e4f1b`)

## Primary Competitive Closure Areas

- Publish benchmark, packaging, and Rails-oriented guidance at the standard expected by
the top Ruby database gems.
- Broaden documentation around encoding, copy/streaming, and operational diagnostics.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
