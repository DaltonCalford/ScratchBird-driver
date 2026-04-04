# Elixir/Ecto driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `elixir`
Selected benchmark: `Postgrex`
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

- Expose standalone public stream/paging helpers and stronger deterministic stream proof.
- Close the remaining resilience gap so reconnect/recovery behavior is competitive with
Postgrex operationally.
- Document telemetry and Ecto integration expectations as first-class contractual
requirements.

## Required Spec Closure

- Expand the Ecto adapter spec with benchmark-driven stream, telemetry, and reconnect
semantics.
- Require end-to-end Ecto and direct-driver evidence in the release pack.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/elixir/`.
