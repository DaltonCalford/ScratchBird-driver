# Node.js/TypeScript driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `node`
Selected benchmark: `node-postgres`
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

- Publish benchmark and operational evidence at the level expected from top Node drivers.
- Refine cancellation, cursor, and pool troubleshooting guidance for framework
integrators.
- Broaden examples for TypeScript-heavy application patterns.

## Required Spec Closure

- Add node-postgres-class release evidence and framework-integration examples to the Node
spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/node/`.
