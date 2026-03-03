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
     - catalogs/keys/privileges/type-info query constants.
2. Added first-class executable metadata API surface on `Client` in `src/client.rs`:
   - `query_metadata(collection)` for collection-routed metadata execution.
   - `metadata_collection_name(collection)` for normalized metadata collection naming.
3. Added focused lane tests in `tests/metadata_test.rs` for:
   - database->default branch-style metadata rows (`TABLE_SCHEM`) expansion,
   - dotted parent expansion behavior,
   - uniqueness within the same parent,
   - same leaf name under different parents,
   - metadata alias/query resolver coverage for extended families.
4. Added metadata API unit coverage in `src/client.rs` tests for unsupported-collection and connected-client requirements.
5. Updated `BASELINE_REQUIREMENT_MAPPING.md` META evidence row and recommendation.

## Tests Run

1. `cargo test --test metadata_test`  
   Result: PASS (`6 passed, 0 failed`)
2. `cargo test --lib metadata_collection_name_rejects_unknown_collection query_metadata_rejects_unknown_collection_before_connect query_metadata_requires_connected_client_for_supported_collection`
   Result: PASS (`3 passed, 0 failed`)

## META Status Recommendation

Recommendation: `PARTIAL`

Why:
- This lane now has metadata-only recursive schema shaping and first-class metadata collection routing/execution APIs on `Client`.
- Status remains partial because restriction mapping and live metadata integration coverage are still incomplete across the full metadata surface.

## Remaining Gaps

1. Restriction-value handling and richer metadata payload shaping are not yet exposed as first-class APIs.
2. No metadata-focused live integration assertions against a running server/tooling flow.
