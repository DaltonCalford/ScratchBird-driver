# DBeaver integration Best-In-Class Gap Report

Date: 2026-04-03
Lane: `dbeaver`
Selected benchmark: `DBeaver PostgreSQL extension`
Current lane state: `partial_plugin`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 3
- `partial_gap`: 11
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Expand navigator and schema-tree behavior to match the first-party DBeaver extensions
without resorting to manual toggles.
- Add explain/plan, DDL editor, and richer metadata view integration.
- Harden stock-install and update-site packaging/documentation for enterprise installs.

## Required Spec Closure

- Create a dedicated DBeaver compatibility specification with plugin packaging, metadata,
and UI behavior requirements.
- Make update-site build/install validation and schema-tree goldens part of release
evidence.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/dbeaver/`.
