# DBeaver Integration

Status: Updated 2026-03-13
Priority: P0
Category: Database Tool

## Purpose

Provide the implementation-facing documentation pack for the ScratchBird
DBeaver adapter that lives in:

- `tracks/alpha/integrations/scratchbird-dbeaver-driver/`

This repo-local doc set is a working mirror for engineers in
`ScratchBird-driver`. Canonical findings, contract, and workplan artifacts live
under `~/CliWork/local_work/docs/specifications/work/`.

The current tracked adapter is a foundation layer. The target scope for this
doc pack is now a complete DBeaver-native ScratchBird implementation, not only
connect-and-browse support.

## Canonical Planning Artifacts

- `~/CliWork/local_work/docs/specifications/work/findings/SCRATCHBIRD_DBEAVER_ADAPTER_FINDINGS_2026-03-13.md`
- `~/CliWork/local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_ADAPTER_CONTRACT_2026-03-13.md`
- `~/CliWork/local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_ADAPTER_WORKPLAN_2026-03-13.md`

## Contents

- `SPECIFICATION.md`
  - implementation-facing summary of the full adapter contract
- `IMPLEMENTATION_PLAN.md`
  - repo-local execution phases for full DBeaver feature coverage
- `COMPATIBILITY_MATRIX.md`
  - capability-by-capability snapshot across DBeaver feature families
- `API_REFERENCE.md`
  - plugin/module IDs, extension-point families, scripts, and notable knobs
- `TESTING_CRITERIA.md`
  - required validation gates for JDBC, plugins, UI, and packaging
- `MIGRATION_GUIDE.md`
  - how to move from ad-hoc DBeaver staging to the tracked adapter lane

## Source of Truth Rules

1. Adapter source files belong in
   `tracks/alpha/integrations/scratchbird-dbeaver-driver/`.
2. JDBC-generic behavior belongs in `tracks/p3/drivers/jdbc/` only when it is
   beneficial beyond DBeaver.
3. ScratchBird DBeaver work should plan for both a core plugin and a companion
   UI plugin when the implementation moves beyond the current foundation layer.
4. The local `~/CliWork/dbeaver` checkout is a staging target, not the source
   of truth.
