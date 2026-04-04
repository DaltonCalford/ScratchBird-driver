# Hibernate dialect Best-In-Class Gap Report

Date: 2026-04-03
Lane: `hibernate`
Selected benchmark: `Hibernate PostgreSQLDialect`
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

- Move from deterministic dialect helpers to full schema tooling, DDL generation, and
entity lifecycle validation.
- Close pagination, locking, generated key, and type contribution gaps against the
strongest PostgreSQL dialect behavior.
- Add migration and integration-test evidence instead of relying only on contract-unit
coverage.

## Required Spec Closure

- Create a Hibernate compatibility spec with dialect, ORM lifecycle, DDL, and migration
acceptance gates.
- Add live ORM bootstrap and schema-management evidence requirements.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/hibernate/`.
