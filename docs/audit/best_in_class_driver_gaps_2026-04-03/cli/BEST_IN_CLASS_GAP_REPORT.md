# CLI tooling lane Best-In-Class Gap Report

Date: 2026-04-03
Lane: `cli`
Selected benchmark: `psql`
Current lane state: `partial_tooling`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 4
- `partial_gap`: 10
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Close metadata and schema-browser coverage so CLI tooling can match psql-style
introspection depth.
- Expand scripting/import/export and output-format ergonomics to compete with psql and
usql automation flows.
- Improve platform packaging and runtime portability beyond Linux-first coverage.

## Required Spec Closure

- Create a first-class CLI tools specification covering command surface, scripting, output
modes, and copy/import/export semantics.
- Make benchmarked script execution, formatting, and metadata tasks part of Beta 1 release
evidence.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/cli/`.
