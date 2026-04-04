# PHP driver Implementation Anchors

Date: 2026-04-03
Lane: `php`
Selected benchmark: `PDO_PGSQL`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/php/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `PDO_PGSQL source`: https://github.com/php/php-src/tree/master/ext/pdo_pgsql
- `PHP source repo`: https://github.com/php/php-src (`refs/heads/master b7c855f4c2d9a79e6f9bd84a4a40805980542e97`)
- `ext-pgsql source`: https://github.com/php/php-src/tree/master/ext/pgsql
- `amphp/postgres repo`: https://github.com/amphp/postgres (`refs/heads/2.x b68c4d5929d0ec1701781dbbb0bb81dd8d0a42d7`)

## Primary Competitive Closure Areas

- Expand packaging and framework guidance to match the clarity of mainstream PHP database
stacks.
- Publish benchmark and memory/streaming evidence for long-running app workloads.
- Add more typed error and parameter-binding examples for PDO-style adopters.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
