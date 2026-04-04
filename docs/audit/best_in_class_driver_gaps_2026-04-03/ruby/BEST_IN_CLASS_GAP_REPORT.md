# Ruby driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `ruby`
Selected benchmark: `ruby-pg`
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

- Publish benchmark, packaging, and Rails-oriented guidance at the standard expected by
the top Ruby database gems.
- Broaden documentation around encoding, copy/streaming, and operational diagnostics.

## Required Spec Closure

- Add ruby-pg-class release evidence and framework examples to the Ruby spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/ruby/`.
