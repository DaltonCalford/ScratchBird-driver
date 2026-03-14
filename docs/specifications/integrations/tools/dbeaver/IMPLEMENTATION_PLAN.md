# DBeaver Integration Implementation Plan

Status: Updated 2026-03-13
Priority: P0
Category: Database Tool

Canonical workplan:

- `~/CliWork/local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_ADAPTER_WORKPLAN_2026-03-13.md`

## Phase 0 - Source-of-Truth Stabilization

1. Keep the adapter code in
   `tracks/alpha/integrations/scratchbird-dbeaver-driver/`.
2. Treat `~/CliWork/dbeaver` as a verification checkout only.
3. Keep install script patching idempotent.
4. Keep driver docs indexed to the integration lane.

Status:

1. adapter lane present
2. docs indexed
3. installer idempotency tightened on 2026-03-13

## Phase 1 - Module Topology Expansion

1. Plan the split between ScratchBird core plugin and ScratchBird UI plugin.
2. Update packaging/install flow to support both modules.
3. Keep the current foundation plugin stable while the UI layer is added.

## Phase 2 - SQL Dialect Completion

1. Add `sqlDialect`.
2. Add SQL editor rule-provider integration where required.
3. Validate autocomplete and formatter behavior.

## Phase 3 - Object Editing Completion

1. Add `objectManager` coverage.
2. Add `databaseEditor` pages and object configurators.
3. Define which ScratchBird object families are mutable from DBeaver.

## Phase 4 - Connection/Auth/Value UX

1. Add `dataSourceView` connection pages.
2. Add `networkHandler`, `dataSourceAuth`, and `ui.propertyConfigurator` where
   ScratchBird-specific UX is needed.
3. Add `dataTypeProvider` and `dataManager` support for ScratchBird value
   behavior.

## Phase 5 - Operational Integration

1. Add `task`, `tools`, `task.ui`, `dashboard`, `sqlGenerator`, `sqlCommand`,
   and `sqlBackup` only where ScratchBird has real backing capability.
2. Decide whether native-client metadata or Maven repository support is needed.

## Phase 6 - Packaging and Stock Install Validation

1. Build ScratchBird JDBC JAR.
2. Build the standalone p2 update site.
3. Install into a stock DBeaver binary.
4. Attach the local JDBC JAR when testing unpublished builds.
5. Verify connect plus recursive-schema browsing plus ScratchBird-native editor
   behaviors.

Status:

1. packaging assets implemented
2. full end-to-end full-feature validation still pending

## Phase 7 - Source Checkout Validation

1. Seed a clean DBeaver source checkout from the tracked adapter lane.
2. Verify patched reactor and feature files remain single-entry.
3. Run the targeted DBeaver plugin/test build.

Status:

1. staging checkout exists locally
2. current checkout still contains a duplicate db-feature plugin line that
   should be normalized before the next clean verification run

## Phase 8 - Promotion Readiness

1. Decide when the adapter is mature enough for promotion beyond the alpha
   integration lane.
2. Decide whether upstream DBeaver contribution is a near-term goal.
