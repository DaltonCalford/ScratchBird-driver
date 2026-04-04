# Node.js/TypeScript driver Implementation Anchors

Date: 2026-04-03
Lane: `node`
Selected benchmark: `node-postgres`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/nodejs-typescript/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `node-postgres docs`: https://node-postgres.com/
- `node-postgres repo`: https://github.com/brianc/node-postgres (`refs/heads/master c78b302666d593007359eb2bd223c5b325a07058`)
- `mysql2 docs`: https://sidorares.github.io/node-mysql2/docs
- `tedious repo`: https://github.com/tediousjs/tedious (`refs/heads/master 529402b943753d47988cc6c8d3babd91c85dd824`)

## Primary Competitive Closure Areas

- Publish benchmark and operational evidence at the level expected from top Node drivers.
- Refine cancellation, cursor, and pool troubleshooting guidance for framework
integrators.
- Broaden examples for TypeScript-heavy application patterns.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
