# JDBC driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `jdbc`
Selected benchmark: `pgjdbc`
Current lane state: `full_parity`

## Verdict

ScratchBird is already at strong baseline parity but still behind the best benchmark in release/polish categories.

## Classification Counts

- `at_parity`: 10
- `partial_gap`: 4
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Benchmark and publish metadata breadth, large-object, batch, and performance evidence at
pgjdbc quality.
- Tighten framework-facing guidance for Hibernate, Spring, BI tooling, and migration
ecosystems.
- Raise packaging/release cadence documentation to the standard of major JDBC providers.

## Required Spec Closure

- Introduce a JDBC competitive-closure supplement that freezes pgjdbc-class metadata and
release evidence expectations.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/jdbc/`.
