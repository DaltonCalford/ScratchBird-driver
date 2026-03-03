# S3 Metadata Implementation (DLB-PYTHON-004)

Scope: `tracks/alpha/drivers/python` lane only.

## Changes

- Expanded metadata lane surface in `src/scratchbird/metadata.py`:
  - Added `schema_name_matches_pattern(...)` with JDBC-style `%` and `_` wildcard behavior (including escape handling).
  - Added `schema_paths_for_navigation(...)` to normalize/de-dupe/filter schema names and optionally enable parent expansion mode.
  - Added `expand_schema_parent_paths(...)` to emit recursive dotted parent segments for metadata-only tree navigation parity.
  - Added `SchemaTreeNode` and `build_schema_tree(...)` for metadata-only recursive schema tree shaping with per-parent uniqueness and terminal-node tracking.
  - Preserved existing metadata query helpers (`schemas_query`, `tables_query`, `columns_query`, `indexes_query`, `index_columns_query`, `constraints_query`, `procedures_query`, `functions_query`).
- Exported new metadata helpers from `src/scratchbird/__init__.py` for lane-visible API usage.
- Added metadata expansion config alias wiring in `src/scratchbird/connection.py`:
  - `ConnectionConfig.metadata_expand_schema_parents` with DSN/kwargs alias mapping equivalent to JDBC naming variants (`metadataExpandSchemaParents`, `metadata_expand_schema_parents`, `expand_schema_parents`, `dbeaver_expand_schema_parents`, etc.).
- Added targeted lane tests:
  - New `tests/test_metadata_recursive_schema.py` validates wildcard matching, parent expansion, pattern-filter preservation, per-parent uniqueness, and cross-schema same-name identity behavior.
  - Extended `tests/test_connection_auth_protocol.py` with alias mapping coverage for `metadata_expand_schema_parents`.
- Updated `BASELINE_REQUIREMENT_MAPPING.md` META row evidence/notes to reflect recursive metadata behavior and tests.

## Tests Run

1. `pytest -q tests/test_metadata_recursive_schema.py tests/test_connection_auth_protocol.py`
- Result: PASS (`12 passed`)

## META Status Recommendation

- Recommendation: `PARTIAL`
- Reason:
  - This lane now has explicit metadata-only recursive schema tree support utilities and focused lane tests proving parent-expansion behavior, parent uniqueness, and cross-path same-name handling.
  - Existing metadata query helper coverage is retained.
  - Status remains partial because the lane does not yet expose complete executable metadata APIs for all baseline families (catalog/key/privilege/type) and does not yet have end-to-end DDL editor metadata payload validation against a live connection.

## Remaining Gaps

- No first-class executable metadata API surface on `Connection`/`Cursor` that returns structured metadata objects or rowsets directly for all required baseline metadata families.
- Catalog/key/privilege/type-family parity is incomplete at lane API/test level (query constants alone are not full parity evidence).
- No integration-level metadata tree verification against a live server/tooling flow to confirm full DDL editor field expectations.
