# R driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `r`
Selected benchmark: `RPostgres`
Current lane state: `partial`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 7
- `partial_gap`: 7
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Close connection/auth environment-gated proof and stronger runtime examples.
- Expand metadata, DDL-editor, and privilege-related introspection parity.
- Improve packaging, reproducibility, and data-frame shaping evidence for R users.

## Required Spec Closure

- Promote RPostgres-class DBI ergonomics and metadata expectations into the R lane spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/r/`.
