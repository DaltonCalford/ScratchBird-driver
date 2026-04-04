# C/C++ driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `cpp`
Selected benchmark: `libpqxx`
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

- Add benchmark-backed performance and memory-footprint evidence comparable to libpqxx’s
mature deployment posture.
- Tighten diagnostic and tracing documentation so operational debugging is as easy as the
incumbent C++ stack.
- Expand package/distribution guidance for Linux, Windows, and ABI-safe consumption.

## Required Spec Closure

- Require benchmark and allocator evidence in the release contract for the C++ lane.
- Codify advanced prepared reuse, large result streaming, and TLS diagnostics examples.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/cpp/`.
