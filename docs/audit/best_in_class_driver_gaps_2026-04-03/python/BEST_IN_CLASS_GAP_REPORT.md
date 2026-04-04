# Python driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `python`
Selected benchmark: `psycopg3`
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

- Publish benchmark and async/runtime evidence at the standard expected by top Python
drivers.
- Broaden packaging and framework integration guidance beyond baseline usage.
- Strengthen documentation for advanced codecs, cancellation, and copy/stream patterns.

## Required Spec Closure

- Add psycopg3-class release evidence and advanced adaptation examples to the Python spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/python/`.
