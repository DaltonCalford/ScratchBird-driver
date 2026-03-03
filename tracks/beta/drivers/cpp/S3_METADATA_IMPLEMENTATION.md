# S3 Metadata Implementation (DLB-CPP-004)

## Scope

- Lane: `tracks/beta/drivers/cpp`
- Focus: metadata-only recursive schema shaping parity against JDBC baseline expectations.

## Changes

- Added lane-local metadata shaping API surface:
  - `include/scratchbird/client/metadata.h`
    - `metadataSchemaPathsForNavigation(...)` for optional dotted parent expansion.
    - `buildMetadataSchemaTree(...)` for recursive metadata-only schema tree construction.
    - `buildMetadataSchemaTreeRows(...)` for flattened metadata rows with database-root + schema-branch shape.
- Added implementation in `src/metadata.cpp`:
  - Path normalization and dotted-segment parsing.
  - Parent expansion with insertion-order de-duplication.
  - Recursive tree build keyed by full path to preserve:
    - parent uniqueness (no duplicate child under one parent),
    - same-name leaf nodes under different parents as distinct nodes.
  - Metadata row shaping beginning from database root, then top-level schema branches and descendants.
- Added focused S3 tests in `tests/test_metadata_schema_tree.cpp`:
  - `TreeRowsStartAtDatabaseAndExposeTopBranches`
  - `ParentExpansionAddsDottedSchemaAncestors`
  - `ParentDoesNotAllowDuplicateChildNames`
  - `SameLeafNameUnderDifferentParentsIsPreserved`
- Wired source/test into build in `CMakeLists.txt`.
- Updated `BASELINE_REQUIREMENT_MAPPING.md` META evidence and remaining-gap notes.

## Test Commands Run

1. `cmake --build build_odbc_gate -j4`
   - Result: `PASS`
2. `./build_odbc_gate/scratchbird_client_tests --gtest_filter=MetadataSchemaTreeTest.*`
   - Result: `PASS` (`4` passed, `0` failed)

## META Status Recommendation

- Recommendation: `PARTIAL`
- Reason:
  - Implemented and tested metadata-only recursive schema shaping, parent expansion mode, database-root/top-branch row shape, per-parent uniqueness, and cross-parent same-name preservation.
  - Lane still lacks broader executable metadata API families and full DDL-editor metadata completeness required for full `JDBCBL-META` parity.

## Remaining Gaps

- Add metadata family APIs/evidence for catalog/key/privilege/type surfaces.
- Add metadata query + `sb_get_column_meta` verification using concrete metadata result flows.
- Add DDL-editor field-completeness coverage beyond schema-tree shaping behavior.
