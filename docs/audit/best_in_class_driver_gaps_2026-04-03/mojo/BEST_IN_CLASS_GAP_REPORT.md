# Mojo driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `mojo`
Selected benchmark: `Composite (asyncpg + pgx + PostgresNIO)`
Current lane state: `hybrid_native_gap`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 0
- `partial_gap`: 14
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Replace the Python bridge with a native transport/runtime path.
- Close native TLS, streaming, type-wrapper, and packaging gaps using the composite
benchmark as the target bar.
- Add first-class examples and performance proof once the transport cutover lands.

## Required Spec Closure

- Promote native transport cutover from checklist work to a hard competitive-closure
requirement.
- Define composite benchmark acceptance gates in the Mojo spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/mojo/`.
