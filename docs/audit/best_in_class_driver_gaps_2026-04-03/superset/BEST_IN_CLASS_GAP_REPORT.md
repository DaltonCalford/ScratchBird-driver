# Superset adapter Best-In-Class Gap Report

Date: 2026-04-03
Lane: `superset`
Selected benchmark: `Superset PostgreSQL engine spec`
Current lane state: `partial_adapter`

## Verdict

ScratchBird is not yet at best-in-class parity for this lane.

## Classification Counts

- `at_parity`: 3
- `partial_gap`: 11
- `full_gap`: 0
- `intentional_non_goal`: 0
- `better_than_benchmark`: 0

## Highest-Priority Gaps

- Expand engine-spec capability flags, time grains, and SQL Lab behavior to match first-
party backends.
- Add end-to-end dataset discovery, async query, and dashboard validation.
- Harden package/install guidance for real Superset deployments.

## Required Spec Closure

- Expand the Superset compatibility spec with benchmark-driven engine-spec, SQL Lab, and
deployment requirements.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/superset/`.
