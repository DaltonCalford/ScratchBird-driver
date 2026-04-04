# Go driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `go`
Selected benchmark: `pgx`
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

- Strengthen benchmark-backed evidence for high-concurrency and large-result performance.
- Refine documentation around pooling, cancellation, and advanced codecs to exceed pgx
usability.
- Broaden ecosystem guidance for ORMs and migration tools.

## Required Spec Closure

- Promote pgx-class benchmarks, pool diagnostics, and advanced examples into the Go driver
acceptance criteria.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/go/`.
