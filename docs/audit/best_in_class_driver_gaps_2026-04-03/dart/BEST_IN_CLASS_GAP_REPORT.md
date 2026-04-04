# Dart driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `dart`
Selected benchmark: `postgres (Dart)`
Current lane state: `partial`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 2
- `partial_gap`: 12
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Complete transaction failure-path, suspend/resume, and resilience proof to the level
expected by the leading Dart driver.
- Fill metadata restriction and DDL payload coverage gaps for tooling ecosystems.
- Broaden live complex-type codecs and runtime SQLSTATE/error propagation proof.

## Required Spec Closure

- Promote live metadata, stream resume, and failure-path certification from optional to
required release evidence.
- Expand the Dart spec with benchmark-derived async ergonomics, metadata, and codec
acceptance criteria.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/dart/`.
