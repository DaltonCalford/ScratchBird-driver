# S3 META Implementation (DLB-PASCAL-004)

Scope: `tracks/alpha/drivers/pascal` only.

## What Changed

- Added metadata-only recursive schema shaping in `src/ScratchBird.Metadata.pas`:
  - Introduced metadata row model (`TMetadataField`, `TMetadataRow`, `TMetadataRows`) and case-insensitive field lookup (`MetadataRowTryGetValue`).
  - Added `ExpandSchemaPaths` for dotted parent expansion with first-seen ordering and de-duplication.
  - Added `ListMetadataSchemaPaths` for schema-path extraction from metadata rows with optional parent expansion mode.
  - Added `ExpandSchemaMetadataRows` for metadata-row parent expansion that emits synthetic ancestor rows and preserves physical leaf rows.
  - Added `TMetadataSchemaTreeNode`/`TMetadataSchemaTree` plus `BuildMetadataSchemaTree` for recursive schema tree shaping with:
    - per-parent uniqueness semantics,
    - terminal-node tracking,
    - same leaf-name support under different parent branches,
    - optional database label on the output tree.
- Added focused FPC test program `tests/MetadataRecursiveSchemaTests.pas` that covers:
  - database/default branch-style metadata row expansion,
  - dotted parent expansion ordering and de-duplication,
  - per-parent uniqueness,
  - same leaf name under different parents.
- Updated `BASELINE_REQUIREMENT_MAPPING.md` META evidence/notes for the new S3 metadata shaping coverage.

## Targeted Tests Run

1. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FE./tracks/alpha/drivers/pascal/tests ./tracks/alpha/drivers/pascal/tests/MetadataRecursiveSchemaTests.pas`
- Result: PASS (compile succeeded).

2. `./tracks/alpha/drivers/pascal/tests/MetadataRecursiveSchemaTests`
- Result: PASS (`MetadataRecursiveSchemaTests: OK`).

## META Status Recommendation

- Recommendation: `PARTIAL`

Rationale:
- Metadata-only recursive schema shaping parity is now implemented in-lane and covered by deterministic lane tests for parent expansion and uniqueness semantics.
- Status remains partial because the lane still lacks first-class executable metadata APIs on client/adapters for full JDBC metadata-family parity.

## Remaining Concrete Gaps

- No client/adapter metadata execution surface yet (query builders are present, but no callable metadata collection APIs).
- No metadata-focused live integration assertions against a running ScratchBird endpoint.
- Broader JDBC metadata family coverage (catalog/key/privilege/type families and richer restriction mapping) remains open.
