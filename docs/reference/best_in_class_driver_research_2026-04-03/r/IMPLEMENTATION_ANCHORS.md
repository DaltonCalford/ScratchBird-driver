# R driver Implementation Anchors

Date: 2026-04-03
Lane: `r`
Selected benchmark: `RPostgres`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/r/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `RPostgres docs`: https://rpostgres.r-dbi.org/
- `RPostgres repo`: https://github.com/r-dbi/RPostgres (`refs/heads/main 8645e6a8f55e258393509c04d0b47f978ac47615`)
- `RMariaDB docs`: https://rmariadb.r-dbi.org/
- `R odbc docs`: https://odbc.r-dbi.org/

## Primary Competitive Closure Areas

- Close connection/auth environment-gated proof and stronger runtime examples.
- Expand metadata, DDL-editor, and privilege-related introspection parity.
- Improve packaging, reproducibility, and data-frame shaping evidence for R users.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
