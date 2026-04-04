# Driver Best-In-Class Competitive Execution Tracker (2026-04-03)

Status: Completed
Last Updated: 2026-04-03

## Purpose

Track execution of the competitive-closure program defined in:

- `DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_WORKPLAN_2026-04-03.md`
- `DRIVER_BEST_IN_CLASS_COMPETITIVE_DRIVER_MATRIX_2026-04-03.csv`
- `DRIVER_BEST_IN_CLASS_COMPETITIVE_ORDERED_TICKETS_2026-04-03.csv`

This tracker now covers the full Beta 1 class cross-repo surface:

- native application drivers
- CLI tooling
- BI/application adapters

## State Model

Use one of these states for every ticket:

- `planned`
- `in_progress`
- `blocked`
- `research_complete`
- `gap_report_complete`
- `spec_complete`
- `closed`

## Execution Order

### Phase 0: Global Baseline

- `BIC-000`

Acceptance:

- scoring rubric frozen
- in-scope lane list frozen
- research and gap-report output paths frozen
- benchmark-selection rules frozen

### Phase 1: Per-Lane Research Packets

Run one lane at a time or in small parallel groups. For each lane:

1. freeze current ScratchBird truth
2. build benchmark candidate pool
3. download sources and examples
4. score and select best-in-class benchmark
5. publish `REFERENCE_MANIFEST.csv`

No lane may enter Phase 2 without a completed benchmark selection document.

### Phase 2: Per-Lane Competitive Gap Reports

For each lane:

1. compare ScratchBird vs selected benchmark category by category
2. classify each area as `at_parity`, `better_than_benchmark`,
   `partial_gap`, `full_gap`, or `intentional_non_goal`
3. capture exact source anchors and examples
4. publish both narrative and CSV outputs

### Phase 3: Spec Closure

For each lane:

1. update the current driver or adapter spec(s)
2. add benchmark-derived required behavior
3. add examples, acceptance criteria, and explicit remaining implementation
   deltas
4. ensure the resulting spec is implementation-ready for a low-reasoning AI

### Phase 4: Global Closeout

- `BIC-999`

Acceptance:

- all per-lane tickets are at least `spec_complete`
- no lane lacks benchmark evidence
- no lane lacks a gap report
- no lane lacks updated specifications

## Lane Groups

### Group A: Highest-leverage core drivers

- `dotnet`
- `jdbc`
- `go`
- `python`
- `node`
- `rust`

Reason:

- these are already strong or complete lanes, and they set the quality bar for
  the rest of the portfolio

### Group B: Partial core drivers

- `dart`
- `elixir`
- `odbc`
- `r`
- `swift`

Reason:

- these already have visible parity gaps and need benchmark-driven closure

### Group C: Specialized driver lanes

- `cpp`
- `pascal`
- `php`
- `ruby`
- `mojo`

Reason:

- they need more tailored benchmark selection logic, especially `mojo`

### Group D: Tooling lane

- `cli`

Reason:

- this lane is outside pure JDBC/.NET parity, but it must reach Beta 1 class
  operational tooling quality across interactive, scripted, and automation
  flows

### Group E: BI/application adapters

- `dbeaver`
- `hibernate`
- `metabase`
- `prisma`
- `sqlalchemy`
- `superset`
- `typeorm`

Reason:

- these lanes define ecosystem adoption quality and must be benchmarked
  against best-in-class integrations, not just raw driver behavior

## Minimum Evidence Required Before Marking Any Lane `research_complete`

- official documentation downloaded or indexed
- source repository or pinned source snapshot captured where available
- benchmark candidate scorecard completed
- benchmark selection rationale written
- at least one real code/example path captured for:
  - connect/auth
  - transactions
  - prepared execution or equivalent query API
  - metadata/introspection
  - errors/diagnostics
  - streaming, paging, reflection, or tool-specific execution path

## Minimum Evidence Required Before Marking Any Lane `gap_report_complete`

- competitive feature matrix complete
- each category classified
- each gap backed by both ScratchBird and benchmark source anchors
- explicit statement on whether the gap is required for parity, optional, or an
  intentional non-goal

## Minimum Evidence Required Before Marking Any Lane `spec_complete`

- lane spec updated
- benchmark-derived requirements written into the spec
- concrete examples and failure cases added
- release evidence expectations updated where needed
- outstanding implementation tasks clearly enumerated

## Current Tracker Summary

| Lane | Research | Gap Report | Spec Closure | Overall |
| --- | --- | --- | --- | --- |
| `cpp` | closed | closed | closed | closed |
| `cli` | closed | closed | closed | closed |
| `dart` | closed | closed | closed | closed |
| `dbeaver` | closed | closed | closed | closed |
| `dotnet` | closed | closed | closed | closed |
| `elixir` | closed | closed | closed | closed |
| `go` | closed | closed | closed | closed |
| `hibernate` | closed | closed | closed | closed |
| `jdbc` | closed | closed | closed | closed |
| `metabase` | closed | closed | closed | closed |
| `mojo` | closed | closed | closed | closed |
| `node` | closed | closed | closed | closed |
| `odbc` | closed | closed | closed | closed |
| `pascal` | closed | closed | closed | closed |
| `php` | closed | closed | closed | closed |
| `prisma` | closed | closed | closed | closed |
| `python` | closed | closed | closed | closed |
| `r` | closed | closed | closed | closed |
| `ruby` | closed | closed | closed | closed |
| `rust` | closed | closed | closed | closed |
| `sqlalchemy` | closed | closed | closed | closed |
| `superset` | closed | closed | closed | closed |
| `swift` | closed | closed | closed | closed |
| `typeorm` | closed | closed | closed | closed |

## Definition of Done

This execution tracker is closed only when:

- `BIC-000` is `closed`
- every in-scope lane has `spec_complete`
- `BIC-999` is `closed`
