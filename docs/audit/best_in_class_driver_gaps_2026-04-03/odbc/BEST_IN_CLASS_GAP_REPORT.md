# ODBC driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `odbc`
Selected benchmark: `Microsoft ODBC Driver for SQL Server`
Current lane state: `partial`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 8
- `partial_gap`: 6
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Close full-family metadata and catalog-surface gaps against the strongest ODBC drivers.
- Broaden descriptor, cursor, and diagnostics coverage where the commercial benchmark is
stronger.
- Improve platform packaging and installation guidance across Windows and Linux.

## Required Spec Closure

- Use Microsoft ODBC behavior as the target bar but anchor implementation detail against
psqlODBC.
- Expand ODBC metadata and diagnostics requirements in the driver spec.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/odbc/`.
