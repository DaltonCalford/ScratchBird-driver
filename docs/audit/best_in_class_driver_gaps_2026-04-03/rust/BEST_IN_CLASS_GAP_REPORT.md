# Rust driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `rust`
Selected benchmark: `tokio-postgres`
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

- Publish benchmark and concurrency evidence at the standard of the leading Rust async
drivers.
- Expand framework, migration, and ecosystem integration guidance.
- Broaden observability and troubleshooting examples for async workloads.

## Required Spec Closure

- Freeze tokio-postgres-class async and performance evidence into the Rust lane
supplement.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/rust/`.
