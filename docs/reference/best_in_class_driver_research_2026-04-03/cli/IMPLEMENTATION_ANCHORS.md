# CLI tooling lane Implementation Anchors

Date: 2026-04-03
Lane: `cli`
Selected benchmark: `psql`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
S2_TXN_EXEC_IMPLEMENTATION.md; S3_METADATA_IMPLEMENTATION.md; docs/planning/driver-
checklists/cli.md; docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `psql docs`: https://www.postgresql.org/docs/current/app-psql.html
- `PostgreSQL repo`: https://github.com/postgres/postgres (`refs/heads/master d438a36591c58f60e0748b341855ec5519e1e3b4`)
- `usql repo`: https://github.com/xo/usql (`refs/heads/main f7d0fbe808a87e9f6c726e5de2cec1fa284e88f5`)
- `mycli project`: https://www.mycli.net/
- `mycli repo`: https://github.com/dbcli/mycli (`refs/heads/main 788a59113a6251dac077995573439e6da2813741`)

## Primary Competitive Closure Areas

- Close metadata and schema-browser coverage so CLI tooling can match psql-style
introspection depth.
- Expand scripting/import/export and output-format ergonomics to compete with psql and
usql automation flows.
- Improve platform packaging and runtime portability beyond Linux-first coverage.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
