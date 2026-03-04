# S3 META Implementation (DLB-PASCAL-004)

Scope: `tracks/alpha/drivers/pascal` only.

## What Changed

- Added metadata-only recursive schema shaping in `src/ScratchBird.Metadata.pas`:
  - Introduced metadata row model (`TMetadataField`, `TMetadataRow`, `TMetadataRows`) and case-insensitive field lookup (`MetadataRowTryGetValue`).
  - Expanded metadata collection/query coverage and alias normalization to include:
    - `catalogs`, `primary_keys`, `foreign_keys`,
    - `table_privileges`, `column_privileges`,
    - `routines`, `type_info`,
    alongside existing schema/table/column/index/constraint/procedure/function collections.
  - Added `ExpandSchemaPaths` for dotted parent expansion with first-seen ordering and de-duplication.
  - Added `ListMetadataSchemaPaths` for schema-path extraction from metadata rows with optional parent expansion mode.
  - Added `ExpandSchemaMetadataRows` for metadata-row parent expansion that emits synthetic ancestor rows and preserves physical leaf rows.
  - Added `FilterMetadataRowsByRestrictions` for collection-scoped metadata row filtering with:
    - alias-based restriction key matching,
    - `%` / `_` wildcard matching semantics,
    - `null` literal handling for nullable-column restriction matching,
    - unsupported restriction-key ignore behavior.
  - Added `TMetadataSchemaTreeNode`/`TMetadataSchemaTree` plus `BuildMetadataSchemaTree` for recursive schema tree shaping with:
    - per-parent uniqueness semantics,
    - terminal-node tracking,
    - same leaf-name support under different parent branches,
    - optional database label on the output tree.
- Added focused FPC test program `tests/MetadataRecursiveSchemaTests.pas` that covers:
  - database/default branch-style metadata row expansion,
  - dotted parent expansion ordering and de-duplication,
  - per-parent uniqueness,
  - same leaf name under different parents,
  - metadata collection alias/query resolution for catalogs/keys/privileges/type/routines families,
  - restriction filtering behavior for aliases/wildcards/null semantics and unsupported key ignore behavior,
  - client metadata API guard behavior (`unsupported` -> `0A000`, disconnected supported collection -> `08003`).
- Added typed metadata wrapper methods on `TScratchBirdClient` for first-class metadata families:
  - `GetCatalogs`, `GetSchemas`, `GetTables`, `GetColumns`, `GetIndexes`, `GetConstraints`,
  - `GetProcedures`, `GetFunctions`, `GetRoutines`,
  - `GetPrimaryKeys`, `GetForeignKeys`,
  - `GetTablePrivileges`, `GetColumnPrivileges`, `GetTypeInfo`.
- Added materialized metadata row APIs on `TScratchBirdClient`:
  - `QueryMetadataRows(collectionName, restrictions)`
  - `GetSchemaRows(collectionName, restrictions)`
  which execute metadata SQL, materialize `TMetadataRows`, and apply restriction filtering in-lane.
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
- Generic executable metadata APIs now exist on the client (`QueryMetadata` / `GetSchema`) with expanded metadata family coverage.
- Typed client metadata wrappers now exist for the expanded metadata family surface.
- Restriction-aware filtering parity now exists for materialized metadata rows (`FilterMetadataRowsByRestrictions` + `QueryMetadataRows`/`GetSchemaRows`).
- Status remains partial because adapter-level metadata surfaces, live integration depth, and JDBC result-shape parity are still incomplete.

## Remaining Concrete Gaps

- No adapter-level metadata execution API parity yet (current executable surface is client-level and generic).
- No metadata-focused live integration assertions against a running ScratchBird endpoint.
- JDBC metadata result-shape parity remains incomplete for richer per-family columns/flags.
