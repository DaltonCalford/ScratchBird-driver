# Driver Best-In-Class Competitive Closure Workplan (2026-04-03)

Status: Completed
Last Updated: 2026-04-03

## Purpose

Establish a deterministic program for every Beta 1 class driver and adapter
lane across:

- `tracks/p3/drivers/`
- `tracks/alpha/integrations/`
- `tracks/beta/integrations/`

The program exists to:

1. determine the current best-in-class driver(s) or integration(s) for that
   language, tool, or application ecosystem
2. download and index the required reference material
3. produce a precise competitive gap report between ScratchBird and the
   selected benchmark
4. create or expand ScratchBird-driver specifications so each lane is driven
   to parity with or beyond the benchmark

The output must be detailed enough that a low-capability, low-reasoning AI can
execute the later implementation/spec-closure work without guessing.

## Scope

In scope driver lanes:

- `cpp`
- `dart`
- `dotnet`
- `elixir`
- `go`
- `jdbc`
- `mojo`
- `node`
- `odbc`
- `pascal`
- `php`
- `python`
- `r`
- `ruby`
- `rust`
- `swift`

In scope tooling and BI/application adapter lanes:

- `cli`
- `dbeaver`
- `hibernate`
- `metabase`
- `prisma`
- `sqlalchemy`
- `superset`
- `typeorm`

Out of scope for this workplan:

- emulated wire-protocol listeners in the main ScratchBird engine repository

## Architectural Guardrails

- ScratchBird native transport remains `SBWP v1.1`; this workplan does not
  authorize protocol drift.
- MGA/state-based recovery remains the transaction/reconnect truth; no driver
  work may introduce replay-based transaction resurrection.
- The current shared driver canon remains authoritative:
  - `docs/specifications/NATIVE_PROTOCOL_ALIGNMENT.md`
  - `docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md`
  - `docs/specifications/DRIVER_ERROR_MAPPING.md`
  - `docs/specifications/DRIVER_STREAMING_AND_PAGING.md`
  - `docs/specifications/DRIVER_THREAD_SAFETY_POOLING.md`
  - `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- Best-in-class comparison is used to improve ScratchBird’s own drivers, not to
  clone foreign protocols or third-party APIs mechanically.

## Success Criteria

This workplan is complete only when every in-scope lane has:

1. a downloaded and indexed research packet
2. a benchmark selection record with a scored best-in-class decision
3. a current-state vs benchmark gap report
4. specification updates that describe how ScratchBird reaches parity or
   exceeds the benchmark
5. explicit implementation-ready outstanding work with no hidden assumptions

## Required Research Outputs Per Lane

Each driver or adapter lane must produce the following artifacts during
execution:

- `docs/reference/best_in_class_driver_research_2026-04-03/<lane>/REFERENCE_MANIFEST.csv`
- `docs/reference/best_in_class_driver_research_2026-04-03/<lane>/BEST_IN_CLASS_SELECTION.md`
- `docs/reference/best_in_class_driver_research_2026-04-03/<lane>/COMPETITIVE_FEATURE_MATRIX.csv`
- `docs/reference/best_in_class_driver_research_2026-04-03/<lane>/IMPLEMENTATION_ANCHORS.md`
- `docs/audit/best_in_class_driver_gaps_2026-04-03/<lane>/BEST_IN_CLASS_GAP_REPORT.md`
- `docs/audit/best_in_class_driver_gaps_2026-04-03/<lane>/BEST_IN_CLASS_GAP_MATRIX.csv`

Reference packet rules:

- download official docs where available
- download open-source source trees or pinned source snapshots where available
- capture release notes/changelogs for the selected benchmark lane
- include concrete usage examples for:
  - connect/auth/TLS
  - transactions/savepoints
  - prepared statements/batching or equivalent query/statement lifecycle
  - metadata/schema discovery or tool/ORM reflection behavior
  - streaming/paging or tool-specific result-handling behavior
  - type conversion
  - pooling/resilience
  - error/diagnostic surfaces
- include benchmark/performance sources when available
- record exact versions/commits and retrieval dates

## Benchmark Selection Rubric

Each lane must evaluate at least 2-3 candidate benchmark drivers when the
ecosystem allows it. The selected best-in-class benchmark must be justified
with a scored rubric using these dimensions:

- API completeness and standards conformance: 20
- transaction and error semantics correctness: 15
- metadata and tooling compatibility depth: 10
- type fidelity and advanced type support: 10
- performance and batching/streaming behavior: 15
- security/auth/TLS posture: 10
- pooling/resilience/recovery behavior: 10
- documentation/release quality: 5
- ecosystem adoption and maintenance health: 5

Selection rules:

- prefer drivers with inspectable source
- if the de facto benchmark is commercial/closed-source, pair it with an
  inspectable open-source implementation anchor
- avoid choosing an abstraction layer when a direct driver exists
- document why rejected candidates lost

## Required Competitive Comparison Categories

Every gap report must compare ScratchBird vs the selected benchmark in these
same categories:

- connection string and config surface
- auth, TLS, certificates, and secret handling
- protocol/bootstrap/connect behavior
- transaction model and savepoints
- prepared statements, batching, generated keys, callable/proc semantics
- result materialization, streaming, paging, and cancellation
- metadata and schema discovery
- type encode/decode and wrappers
- error surfaces and SQLSTATE mapping
- pooling, resilience, reconnect, keepalive, and lifecycle cleanup
- observability and diagnostics
- package layout, release artifacts, and release cadence
- performance characteristics and benchmark evidence
- ecosystem integration expectations for the language, tool, or application

## Execution Phases

### Phase 0: Freeze Current ScratchBird Truth

For every lane:

1. read the lane-local `BASELINE_REQUIREMENT_MAPPING.md`
   when it exists
2. otherwise read the lane-local checklist or contract `README.md` that
   defines current truth
3. read the current lane spec file(s)
4. read the latest repo-wide driver audit and any adapter/application docs
5. freeze the current ScratchBird truth into the per-lane research packet

No benchmark comparison starts until the ScratchBird baseline is frozen.

### Phase 1: Best-In-Class Research

For every lane:

1. build candidate benchmark set
2. collect official docs
3. collect source repos or pinned source snapshots
4. collect release notes/changelogs
5. collect example applications/tests
6. collect benchmark/performance evidence
7. score candidates
8. produce `BEST_IN_CLASS_SELECTION.md`

### Phase 2: Competitive Gap Reporting

For every lane:

1. compare current ScratchBird lane against the selected benchmark
2. mark each category as:
   - `at_parity`
   - `better_than_benchmark`
   - `partial_gap`
   - `full_gap`
   - `intentional_non_goal`
3. attach concrete evidence anchors for both ScratchBird and the benchmark
4. produce a narrative gap report and machine-readable gap matrix

### Phase 3: Specification Closure

For every lane:

1. update the current lane spec(s)
2. add benchmark-driven required behavior
3. add explicit examples and error cases
4. add non-goal boundaries where ScratchBird should differ intentionally
5. update testing and release-evidence requirements if the benchmark demands it

### Phase 4: Low-Reasoning-AI Handoff Closure

For every lane, the final spec package must contain:

- exact required behavior
- input/output examples
- failure-path examples
- concrete benchmark-derived acceptance criteria
- explicit non-goals
- explicit remaining implementation tasks

## Deliverable Paths

Current plan artifacts:

- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_WORKPLAN_2026-04-03.md`
- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_DRIVER_MATRIX_2026-04-03.csv`
- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_ORDERED_TICKETS_2026-04-03.csv`
- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_EXECUTION_TRACKER_2026-04-03.md`

Execution-time research/artifact roots to be created when this plan is carried
out:

- `docs/reference/best_in_class_driver_research_2026-04-03/`
- `docs/audit/best_in_class_driver_gaps_2026-04-03/`

## Definition of Done

The workplan is only done when:

- all 24 in-scope lanes have completed research packets
- all 24 in-scope lanes have benchmark selections
- all 24 in-scope lanes have gap reports
- all affected specs are updated
- the planning tracker is closed with no `planned` or `in_progress` items left

## Companion Files

- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_DRIVER_MATRIX_2026-04-03.csv`
- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_ORDERED_TICKETS_2026-04-03.csv`
- `docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_EXECUTION_TRACKER_2026-04-03.md`

## Completion Evidence

- `docs/reference/best_in_class_driver_research_2026-04-03/`
- `docs/audit/best_in_class_driver_gaps_2026-04-03/`
- `docs/audit/BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_REPORT.md`
- `docs/specifications/DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_MODEL.md`
