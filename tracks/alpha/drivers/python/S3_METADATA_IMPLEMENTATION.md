# S3 Metadata Implementation (DLB-PYTHON-004)

Scope: `tracks/alpha/drivers/python` lane only.

## Changes

- Expanded metadata lane surface in `src/scratchbird/metadata.py`:
  - Added `schema_name_matches_pattern(...)` with JDBC-style `%` and `_` wildcard behavior (including escape handling).
  - Added `schema_paths_for_navigation(...)` to normalize/de-dupe/filter schema names and optionally enable parent expansion mode.
  - Added `expand_schema_parent_paths(...)` to emit recursive dotted parent segments for metadata-only tree navigation parity.
  - Added `SchemaTreeNode` and `build_schema_tree(...)` for metadata-only recursive schema tree shaping with per-parent uniqueness and terminal-node tracking.
  - Extended executable metadata query coverage with `catalogs`, `primary_keys`, `foreign_keys`, `table_privileges`, `column_privileges`, `type_info`, and `routines`.
  - Added metadata collection normalization/query resolution APIs:
    - `normalize_collection_name(...)`
    - `resolve_collection_query(...)`
- Exported new metadata helpers from `src/scratchbird/__init__.py` for lane-visible API usage.
- Added metadata expansion config alias wiring in `src/scratchbird/connection.py`:
  - `ConnectionConfig.metadata_expand_schema_parents` with DSN/kwargs alias mapping equivalent to JDBC naming variants (`metadataExpandSchemaParents`, `metadata_expand_schema_parents`, `expand_schema_parents`, `dbeaver_expand_schema_parents`, etc.).
- Added first-class executable metadata APIs on `Connection`:
  - `query_metadata(collection_name='tables', restrictions=None)` executes normalized metadata queries via the existing query path.
  - `get_schema(collection_name='tables', restrictions=None)` materializes metadata rows by draining cursor results.
  - Added convenience metadata wrappers for supported families:
    - Existing: `schemas`, `tables`, `columns`, `indexes`
    - Newly expanded: `index_columns`, `constraints`, `catalogs`, `primary_keys`, `foreign_keys`, `procedures`, `functions`, `routines`, `table_privileges`, `column_privileges`, `type_info`
  - Unsupported metadata collections map to `errors.NotSupportedError`.
- Added first-class metadata restriction filtering:
  - `metadata.normalize_restrictions(...)` validates and normalizes restriction keys.
  - `metadata.filter_rows_by_restrictions(...)` applies alias-aware restrictions per metadata family.
  - Supports mapping-row and tuple-row inputs (tuple rows use cursor description column names).
  - Supports null matching with `"null"`, JDBC-style `%`/`_` wildcard restriction matching (including escaped wildcard literals), and ignores unmappable restriction keys.
  - `Connection.query_metadata(...)` now returns an in-memory filtered cursor when restrictions are provided.
- Added targeted lane tests:
  - New `tests/test_metadata_recursive_schema.py` validates wildcard matching, parent expansion, pattern-filter preservation, per-parent uniqueness, and cross-schema same-name identity behavior.
  - New `tests/test_metadata_execution.py` validates alias normalization/query resolution for extended families and `Connection.query_metadata(...)`/`get_schema(...)` behavior (including unsupported collection mapping).
  - Added metadata restriction tests for alias-based filtering, tuple-row filtering with descriptions, null matching, wildcard matching, escaped wildcard literals, unknown key handling, and invalid restriction input mapping.
  - Added wrapper forwarding tests to validate collection + restriction mapping for the expanded convenience wrapper surface.
  - Extended `tests/test_connection_auth_protocol.py` with alias mapping coverage for `metadata_expand_schema_parents`.
  - Added env-gated integration assertions in `tests/test_integration.py` for live metadata wrapper execution and restriction filtering behavior, including wildcard table restrictions.
- Updated `BASELINE_REQUIREMENT_MAPPING.md` META row evidence/notes to reflect recursive metadata behavior and tests.

## Tests Run

1. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests/test_metadata_execution.py tracks/alpha/drivers/python/tests/test_integration.py`
- Result: PASS (`43 passed, 20 skipped`)

2. `PYTHONDONTWRITEBYTECODE=1 pytest -q tracks/alpha/drivers/python/tests`
- Result: PASS (`143 passed, 20 skipped`)

## META Status Recommendation

- Recommendation: `PARTIAL`
- Reason:
  - This lane now has explicit executable metadata collection routing (`query_metadata` / `get_schema`), expanded convenience wrappers across all supported metadata families, dedicated alias/resolver/unsupported-path tests, and first-class restriction-aware filtering with JDBC-style wildcard support.
  - Recursive schema shaping coverage remains in place for nested metadata navigation behavior.
  - Env-gated live integration assertions now cover wrapper execution and restriction filtering behavior, including wildcard table filters.
  - Status remains partial because live metadata validation is still environment-gated and not guaranteed in always-on CI.

## Remaining Gaps

- Live metadata assertions still depend on `SCRATCHBIRD_TEST_DSN`, so default runs can skip this lane.
- DDL-editor payload stability checks are not yet pinned to a fixed fixture schema snapshot in this lane.
