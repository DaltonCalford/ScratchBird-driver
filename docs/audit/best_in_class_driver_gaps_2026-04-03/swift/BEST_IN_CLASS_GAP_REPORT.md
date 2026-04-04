# Swift driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `swift`
Selected benchmark: `PostgresNIO`
Current lane state: `partial`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 3
- `partial_gap`: 11
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Close live cancellation, suspend/resume, metadata, codec, and pool recovery gaps.
- Improve async/await and NIO lifecycle documentation and examples.
- Publish performance and reliability evidence expected in modern Swift server stacks.

## Required Spec Closure

- Promote PostgresNIO-class async, pooling, and codec expectations into the Swift spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/swift/`.
