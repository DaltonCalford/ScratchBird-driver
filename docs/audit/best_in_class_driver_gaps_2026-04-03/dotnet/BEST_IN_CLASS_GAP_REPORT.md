# .NET driver Best-In-Class Gap Report

Date: 2026-04-03
Lane: `dotnet`
Selected benchmark: `Npgsql`
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

- Publish benchmark and operational evidence at the same standard expected of top-tier
ADO.NET providers.
- Tighten integration guidance for ORMs, diagnostics, and pooling scenarios.
- Surface advanced provider ergonomics and troubleshooting guidance more directly in docs.

## Required Spec Closure

- Promote Npgsql-class diagnostics, pooling, and packaging expectations into the .NET spec
supplement.
- Require reproducible benchmark and compatibility matrices in the release evidence pack.

## Matrix Contract

See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
`docs/reference/best_in_class_driver_research_2026-04-03/dotnet/`.
