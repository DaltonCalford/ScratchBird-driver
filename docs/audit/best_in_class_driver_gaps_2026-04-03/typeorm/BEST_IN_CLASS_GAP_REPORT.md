# TypeORM adapter Best-In-Class Gap Report

Date: 2026-04-03
Lane: `typeorm`
Selected benchmark: `TypeORM PostgreSQL driver`
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

- Move from deterministic scaffolding to a full datasource, schema sync, migration, and
relation-loading surface.
- Close metadata reflection and query-builder behavior gaps.
- Add installation, packaging, and framework validation evidence.

## Required Spec Closure

- Create a TypeORM compatibility specification with datasource, migrations, relation, and
query-builder acceptance gates.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/typeorm/`.
