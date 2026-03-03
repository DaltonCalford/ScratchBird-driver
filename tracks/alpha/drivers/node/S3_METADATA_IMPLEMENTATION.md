# DLB-NODE-004 S3 Metadata Implementation

## Changes
- Added a lane-local metadata API surface on `Client`:
  - `getSchema(collectionName)` for supported metadata collections (`catalogs`, `schemas`, `tables`, `columns`, `indexes`, `index_columns`, `constraints`, `primary_keys`, `foreign_keys`, `table_privileges`, `column_privileges`, `procedures`, `functions`, `type_info`).
  - `catalogs` is served locally from configured database context for deterministic metadata availability.
  - Unsupported collections now fail deterministically with `ScratchbirdNotSupportedError` (`0A000`).
  - `getSchema("schemas")` now supports JDBC-like parent expansion when `metadataExpandSchemaParents` is enabled.
- Added metadata helper utilities in `src/metadata.ts`:
  - Collection name normalization and SQL resolver.
  - Recursive schema parent expansion helper.
  - Metadata-only recursive schema tree builder (`buildMetadataSchemaTree`) with parent uniqueness and terminal-node tracking.
- Added DSN/config parity for parent expansion mode:
  - New `ClientConfig.metadataExpandSchemaParents`.
  - DSN aliases: `metadataExpandSchemaParents`, `metadata_expand_schema_parents`, `expandSchemaParents`, `expand_schema_parents`, `dbeaver_expand_schema_parents`.
- Added targeted lane unit coverage for metadata behavior and recursive schema tree shaping.

## Tests Run
- `npm run build && node --test test/unit.test.js` -> PASS
  - 17 tests passed, 0 failed.

## META Status Recommendation
- Recommendation: `PARTIAL`
- Why:
  - Implemented and tested: metadata collection routing across core plus catalog/key/privilege/type families, recursive schema ancestry preservation, metadata-only tree shaping, per-parent uniqueness, same-name separation across different schema parents, and config/DSN parent-expansion mode.
  - Still incomplete for full `JDBCBL-META`: richer DDL-editor payload depth and broader live integration verification.

## Remaining Gaps
- Expand metadata payload coverage for DDL-editor parity where richer key/privilege/type fields are needed.
- Add live integration assertions for metadata API behavior against an actual server/catalog (current coverage is lane unit-level).
