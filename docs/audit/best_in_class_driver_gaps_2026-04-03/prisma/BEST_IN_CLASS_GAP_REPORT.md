# Prisma adapter Best-In-Class Gap Report

Date: 2026-04-03
Lane: `prisma`
Selected benchmark: `Prisma PostgreSQL connector`
Current lane state: `partial_contract_only`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 3
- `partial_gap`: 10
- `full_gap`: 1
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Move from deterministic helper scaffolding to a full provider-quality introspection and
migration surface.
- Close datasource validation, schema reflection, and transaction/runtime behavior gaps.
- Add packaging and framework-facing integration guidance for Prisma users.

## Required Spec Closure

- Create a Prisma compatibility spec with migration, introspection, and runtime acceptance
criteria.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/prisma/`.
