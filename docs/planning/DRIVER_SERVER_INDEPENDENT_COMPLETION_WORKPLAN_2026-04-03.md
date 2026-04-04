# Driver Server-Independent Completion Workplan (2026-04-03)

Status: Completed
Last Updated: 2026-04-03

## Purpose

Drive the `ScratchBird-driver` repository to a clean `server-blocked only`
state.

This workplan covers every meaningful repo task that can be completed without
access to a working ScratchBird test server. The goal is to leave only live
runtime verification, measured conformance execution, and measured performance
collection for the later server-enabled pass.

This plan starts from the current repo truth:

- best-in-class competitive research and gap reports already exist
- lane parity truth is frozen in
  `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- release-evidence requirements are frozen in
  `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- a large amount of spec and integration material still needs offline closure,
  normalization, or authority cleanup

## Definition Of Server-Independent Work

In scope for this plan:

- spec drafting and spec correction
- lane-doc synchronization
- adapter and integration contract closure
- release-evidence schema definition
- benchmark and compatibility methodology definition
- packaging and release-process documentation
- current-truth audits against local code and docs
- authority cleanup, supersession cleanup, and stale-draft classification
- generation of deterministic later verification packets

Out of scope for this plan:

- any test or benchmark that requires a running ScratchBird server
- live contract-test execution
- live conformance reports populated with real pass/fail data
- real compatibility matrices proven against a live server
- measured performance numbers
- package publication to external registries

## Success Criteria

This workplan is complete only when all of the following are true:

1. every Beta 1 lane has one authoritative implementation spec path and one
   authoritative release-evidence path
2. every partial lane and adapter has its remaining gaps explicitly enumerated
   in its own spec
3. every complete lane has benchmark-derived closure requirements pushed into
   its own lane docs instead of only the shared closure model
4. every targeted adapter has authoritative compatibility, API, and getting
   started docs
5. the `docs/specifications/integrations/` tree is classified so template-only,
   superseded, and active material are no longer mixed together ambiguously
6. all later server-required work is reduced to deterministic execution packets
   with no hidden assumptions

## In-Scope Lane Surface

Native application drivers:

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

Tooling:

- `cli`

BI/application adapters:

- `dbeaver`
- `hibernate`
- `metabase`
- `prisma`
- `sqlalchemy`
- `superset`
- `typeorm`

## Required Outputs

This workplan must produce or fully normalize the following output families.

### 1. Lane Spec Closure

For every in-scope lane:

- authoritative implementation spec states whether the lane is:
  - `baseline_complete`
  - `partial`
  - `hybrid_native_gap`
  - `tooling_non_jdbc_lane`
- benchmark target is named
- current lane truth is frozen
- remaining implementation deltas are explicit
- required release evidence is explicit
- later server-verification commands and expected artifacts are explicit

### 2. Release-Evidence Pack Schemas

For every in-scope lane:

- `CONTRACT_TEST_RESULTS` schema
- `CONFORMANCE_REPORT` template
- `COMPATIBILITY_MATRIX` template
- `PERFORMANCE_NUMBERS` methodology and output template
- `KNOWN_GAPS` template with severity rules
- `PACKAGING_AND_RELEASE_CADENCE` template

### 3. Integration Tree Authority Cleanup

The `docs/specifications/integrations/` tree must be normalized so each
directory is classified as one of:

- `authoritative_active`
- `supporting_template_only`
- `future_backlog`
- `superseded_by_top_level_spec`

Every targeted adapter must point to its authoritative top-level spec.

### 4. Server-Verification Packet

For every lane:

- exact commands to run later
- environment variables and prereqs
- expected outputs
- expected artifact paths
- pass/fail rules
- promotion gate mapping

## Workstreams

### Workstream A: Freeze And Push Current Lane Truth

Update every lane package so local specs agree with:

- `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- `docs/audit/BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_REPORT.md`
- lane-local `BASELINE_REQUIREMENT_MAPPING.md`
- lane-local `README.md` and current track docs

No lane may retain hidden gaps that only exist in an audit file.

### Workstream B: Competitive Closure Propagation

The shared competitive-closure model is not enough by itself. The benchmark
requirements must be pushed into each lane’s own:

- `SPECIFICATION.md`
- `IMPLEMENTATION_PLAN.md`
- `TESTING_CRITERIA.md`
- supporting top-level spec when the lane uses one

### Workstream C: Adapter And Tooling Closure

The targeted adapter surfaces must be fully documented without a live server:

- compatibility contracts
- API/reference behavior
- getting-started flows
- offline-known limitations
- later validation commands

### Workstream D: Release Evidence And Packaging Closure

Create deterministic, lane-level release evidence templates and packaging
requirements so later Beta 1 release work is execution-only.

### Workstream E: Integration Tree Rationalization

The current draft-heavy integration tree must be normalized so it no longer
pretends that hundreds of future specs are part of current active closure.

### Workstream F: Server-Handoff Packet

Prepare a single later verification packet so that, once a server exists, a
low-capability agent can run the final proof collection with no ambiguity.

## Execution Phases

### Phase 0: Baseline Freeze

- confirm lane truth against current audits and lane-local mappings
- freeze authoritative file targets for each lane
- freeze which integration directories are active, superseded, or template-only

### Phase 1: Per-Lane Spec Closure

For every driver and tooling lane:

1. update authoritative specs
2. update implementation plans
3. update testing criteria
4. update getting-started and API docs where they are part of the lane surface

### Phase 2: Per-Adapter Closure

For every adapter lane:

1. update authoritative compatibility spec
2. update API/reference doc
3. update getting-started doc
4. mark any older integration subtree pages as supporting or superseded

### Phase 3: Release-Evidence And Verification Contracts

1. create shared schemas/templates
2. create per-lane verification checklists
3. create a consolidated server-verification packet

### Phase 4: Integration Tree And Index Cleanup

1. classify the integration tree
2. update indexes
3. remove ambiguity between authoritative and draft/template docs
4. freeze the final “server-blocked only” state

## Ticket Model

The ordered ticket set for this workplan is in:

- `DRIVER_SERVER_INDEPENDENT_COMPLETION_ORDERED_TICKETS_2026-04-03.csv`

The lane and area matrix is in:

- `DRIVER_SERVER_INDEPENDENT_COMPLETION_MATRIX_2026-04-03.csv`

The live tracker is in:

- `DRIVER_SERVER_INDEPENDENT_COMPLETION_EXECUTION_TRACKER_2026-04-03.md`

## Definition Of Done

This workplan is done only when:

- all ticket rows are at least `spec_complete` or `closed`
- no targeted lane lacks an authoritative implementation spec
- no targeted lane lacks an authoritative later verification packet
- no targeted adapter lacks authoritative compatibility docs
- the integration tree has a deterministic authority map
- all remaining unfinished work in the repo is honestly and explicitly marked as
  `server_blocked`

## Completion Evidence

- lane authority index generated
- release-evidence template pack generated
- per-lane server verification packets generated
- integration-tree authority map generated
- remaining work reduced to explicit server-blocked verification
