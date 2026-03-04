# DLB-RUST-004 S3 Metadata Implementation

Date: 2026-03-03  
Lane: `tracks/alpha/drivers/rust`

## What Changed

1. Added metadata-only recursive schema shaping helpers in `src/metadata.rs`:
   - `MetadataRow` (`HashMap<String, serde_json::Value>`) for metadata row shaping.
   - `expand_schema_paths(...)` for dotted parent expansion while preserving first-seen order.
   - `list_metadata_schema_paths(...)` for schema-path extraction from metadata rows (`schema_name`, `TABLE_SCHEM`, `table_schema`, aliases) with optional parent expansion.
   - `build_metadata_schema_tree(...)` + `MetadataSchemaTreeOptions` for recursive tree generation with:
     - optional parent expansion mode,
     - per-parent uniqueness guarantees,
     - same-leaf-name support under different parent paths,
     - optional database label on output tree.
   - `expand_schema_metadata_rows(...)` for metadata-row parent expansion that emits synthetic parent rows and preserves physical leaf rows.
   - metadata collection alias/query resolvers for extended families:
     - `normalize_metadata_collection_name(...)`
     - `resolve_metadata_collection_query(...)`
     - catalogs/keys/privileges/routines/type-info query constants.
2. Added first-class executable metadata API surface on `Client` in `src/client.rs`:
   - `query_metadata(collection)` for collection-routed metadata execution.
   - `metadata_collection_name(collection)` for normalized metadata collection naming.
   - `query_metadata_with_restrictions(collection, restrictions)` for restriction-aware metadata filtering over metadata result sets (column alias aware for schema/catalog/table/column/index/constraint/routine/type keys) with collection-scoped allowed restriction families, including unified `routines`.
3. Added focused lane tests in `tests/metadata_test.rs` for:
   - database->default branch-style metadata rows (`TABLE_SCHEM`) expansion,
   - dotted parent expansion behavior,
   - uniqueness within the same parent,
   - same leaf name under different parents,
   - metadata alias/query resolver coverage for extended families, including `routines`.
4. Added metadata API unit coverage in `src/client.rs` tests for unsupported-collection, connected-client requirements, and restriction-filter behavior including collection-scoped allowed-key filtering and multi-alias column matching.
5. Added live metadata integration assertion in `tests/integration_test.rs`:
   - `query_metadata_with_restrictions_filters_schema_rows`.
6. Updated `BASELINE_REQUIREMENT_MAPPING.md` META evidence row and recommendation.

## Tests Run

1. `cargo test --test metadata_test`  
   Result: PASS (`6 passed, 0 failed`)
2. `cargo test --lib metadata_collection_name_rejects_unknown_collection query_metadata_rejects_unknown_collection_before_connect query_metadata_requires_connected_client_for_supported_collection`
   Result: PASS (`3 passed, 0 failed`)
3. `cargo test --lib apply_metadata_restrictions query_metadata_with_restrictions_rejects_unknown_collection_before_connect`
   Result: PASS (`5 passed, 0 failed` across filtered runs)
4. `cargo test --test integration_test query_metadata_with_restrictions_filters_schema_rows`
   Result: PASS (`1 passed, 0 failed` with env-gated early-return semantics preserved when DSN is absent)

## META Status Recommendation

Recommendation: `PARTIAL`

Why:
- This lane now has metadata-only recursive schema shaping, first-class metadata collection routing/execution APIs, and restriction-aware metadata filtering on `Client`.
- Status remains partial because deeper metadata integration depth and full DDL-editor payload-parity matrices across all metadata families are still incomplete.

## Remaining Gaps

1. Metadata live integration depth remains limited to focused assertions rather than full DDL-editor payload parity matrices.
