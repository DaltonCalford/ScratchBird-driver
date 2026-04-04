# SQLAlchemy dialect Best-In-Class Gap Report

Date: 2026-04-03
Lane: `sqlalchemy`
Selected benchmark: `SQLAlchemy PostgreSQL dialect`
Current lane state: `partial_adapter`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 3
- `partial_gap`: 11
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Deepen reflection, DDL compilation, and Alembic-facing behavior.
- Add end-to-end ORM lifecycle and migration validation beyond deterministic dialect
tests.
- Improve packaging, docs, and performance evidence for production adoption.

## Required Spec Closure

- Create a SQLAlchemy compatibility specification with reflection, ORM, and migration
acceptance gates.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/sqlalchemy/`.
