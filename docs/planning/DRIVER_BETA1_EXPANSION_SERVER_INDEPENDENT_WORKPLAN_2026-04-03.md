# Driver Beta 1 Expansion Server-Independent Workplan (2026-04-03)

Status: Completed
Last Updated: 2026-04-03

## Purpose

Drive the newly promoted Beta 1 expansion lanes in `ScratchBird-driver` as far
as possible without a working ScratchBird test server.

This workplan exists because ten new lanes have already been promoted to active
Beta 1 authority in `docs/specifications/DRIVER_LANE_AUTHORITY_INDEX.md`, but
they are still at the `planned_beta1` state. The repo can still make major
progress before live validation by freezing benchmark targets, collecting
best-in-class reference material, publishing lane-local gap reports, and
expanding each lane’s specification pack so later implementation and
server-enabled proof work become largely mechanical.

## Starting Repo Truth

The current starting point for this workplan is:

- the new active Beta 1 lanes already have authoritative top-level specs
- each new lane already has:
  - a public getting-started page
  - a public API/reference page
  - a later server-verification packet
- each new lane is still `planned_beta1`, not implemented or live-verified
- the repo already has shared release-evidence contracts and best-in-class
  closure guidance, but the new lanes still need lane-local deepening

## Definition Of Server-Independent Work

In scope for this plan:

- best-in-class benchmark research for each new lane
- explicit gap analysis between benchmark expectations and current ScratchBird
  lane plans
- expansion of each new authoritative spec so it is implementation-ready
- expansion of public getting-started and API/reference docs where needed
- deterministic later verification packet closure for each new lane
- index, authority-map, and supersession cleanup needed by the new lanes
- cross-lane release-evidence expectations specialized for the new lanes

Out of scope for this plan:

- any live runtime validation against a ScratchBird server
- measured compatibility matrices populated from real runs
- measured performance numbers
- package publication
- promotion from `planned_beta1` to `baseline_complete`

## In-Scope Lanes

Drivers:

- `r2dbc`
- `adbc`
- `flightsql`
- `julia`
- `perl`

Adapters:

- `dbt`
- `airbyte`
- `powerbi`
- `tableau`
- `looker`

## Success Criteria

This workplan is complete only when all of the following are true:

1. every in-scope lane has a best-in-class research packet downloaded or
   cataloged in repo-owned reference space
2. every in-scope lane has a lane-local gap report that compares:
   - best-in-class benchmark expectations
   - ScratchBird JDBC/.NET baseline expectations where relevant
   - the current planned lane surface
3. every in-scope lane has one implementation-ready authoritative spec whose
   required capability families, packaging expectations, known constraints, and
   later proof steps are explicit
4. every in-scope lane has authoritative public getting-started and API docs
   that agree with the implementation spec
5. every in-scope lane has a deterministic later server-verification packet
6. all remaining work for the new lanes is explicitly reduced to either:
   - `implementation_pending`
   - `server_blocked`

## Required Output Families

### 1. Per-Lane Research Packet

For every in-scope lane, collect and publish:

- benchmark target and version family
- official documentation links or downloaded references
- implementation-source anchors where useful
- required capability families
- packaging/distribution expectations
- integration expectations for common frameworks or host tools

Recommended root:

- `docs/reference/beta1_expansion_server_independent_2026-04-03/`

### 2. Per-Lane Gap Report

For every in-scope lane, publish a gap report that states:

- what the benchmark provides
- what the ScratchBird JDBC/.NET baseline implies for equivalent families
- what the current ScratchBird lane spec already claims
- what is still missing, grouped by:
  - functional gap
  - metadata/type gap
  - tooling/packaging gap
  - live-proof-only gap

Recommended root:

- `docs/audit/BETA1_EXPANSION_<LANE>_GAP_REPORT.md`

### 3. Per-Lane Spec Closure

For every in-scope lane, deepen the authoritative spec pack so it includes:

- explicit benchmark target
- explicit current lane state
- required capability families
- required metadata and type behavior
- required error, cancellation, retry, and transaction behavior
- packaging and publish targets
- release-evidence requirements
- later verification commands and expected artifacts

### 4. Public Documentation Closure

For every in-scope lane:

- public getting-started guidance must agree with the authoritative spec
- public API/reference guidance must agree with the authoritative spec
- later verification packet must match the planned release evidence

### 5. Cross-Lane Closeout

After all lanes are updated:

- authority indexes must be resynced
- support lists must be resynced
- superseded subtree docs must be explicitly called out where applicable
- a closeout summary must name what remains `implementation_pending` and what
  remains `server_blocked`

## Workstreams

### Workstream A: Baseline Freeze

Freeze the exact active-lane set, benchmark targets, and authoritative file
paths used by this workplan.

### Workstream B: Benchmark Research And Gap Analysis

For each lane, gather the best-in-class benchmark references and publish the
lane-local gap report.

### Workstream C: Per-Lane Spec Deepening

Update each new authoritative spec so a low-capability implementation agent can
work from one lane-local spec package instead of inferring behavior from
multiple repo files.

### Workstream D: Public Docs And Verification Packet Closure

Push the spec truth into getting-started, API/reference, and later
server-verification docs.

### Workstream E: Authority And Index Cleanup

Resync the repo indexes and record any supersession or support-list changes
caused by the new lanes.

## Execution Phases

### Phase 0: Baseline Freeze

- confirm the ten in-scope lanes and their benchmark targets
- freeze the exact authoritative file paths for each lane
- freeze the output roots for research and gap reports

### Phase 1: Per-Lane Research And Gap Reports

For each lane:

1. gather official references and useful implementation anchors
2. summarize benchmark expectations
3. compare benchmark expectations to the current planned ScratchBird lane
4. publish a lane-local gap report

### Phase 2: Per-Lane Spec Closure

For each lane:

1. deepen the authoritative implementation or compatibility spec
2. align the public getting-started guide
3. align the public API/reference guide
4. align the later server-verification packet

### Phase 3: Cross-Lane Index And Closeout

1. update planning indexes if new outputs were created
2. update authority/support indexes if the lane state changed
3. publish a closeout note that isolates `implementation_pending` and
   `server_blocked` work for the new lanes

## Ticket Model

The ordered ticket set for this workplan is in:

- `DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_ORDERED_TICKETS_2026-04-03.csv`

The lane and artifact matrix is in:

- `DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_MATRIX_2026-04-03.csv`

The live execution tracker is in:

- `DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_EXECUTION_TRACKER_2026-04-03.md`

The closeout note is in:

- `DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_CLOSEOUT_2026-04-03.md`

## Definition Of Done

This workplan is done only when:

- every ticket is at least `spec_complete` or `closed`
- every in-scope lane has a research packet and a lane-local gap report
- every in-scope lane has a fully deepened authoritative spec pack
- every remaining unfinished item is explicitly classified as either
  `implementation_pending` or `server_blocked`
