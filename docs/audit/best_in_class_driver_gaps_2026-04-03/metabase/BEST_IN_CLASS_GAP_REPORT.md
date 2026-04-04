# Metabase adapter Best-In-Class Gap Report

Date: 2026-04-03
Lane: `metabase`
Selected benchmark: `Metabase PostgreSQL driver`
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

- Close schema sync and field fingerprinting depth gaps so Metabase behavior matches the
leading first-party plugins.
- Harden capability flags, native query handling, and packaging/deployment guidance.
- Add full end-to-end plugin validation against modern Metabase runtimes.

## Required Spec Closure

- Expand the Metabase compatibility spec with benchmark-driven sync, feature-flag, and
packaging requirements.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/metabase/`.
