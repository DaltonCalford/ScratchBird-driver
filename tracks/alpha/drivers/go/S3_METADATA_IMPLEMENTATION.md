# S3 Metadata Implementation (DLB-GO-004)

Scope: `tracks/alpha/drivers/go` lane only.

## Changes
- Added recursive-schema metadata helpers in `metadata.go`:
  - `MetadataExpandSchemaNames(...)` for optional dotted parent expansion with JDBC-style pattern filtering (`%`, `_`, `\\` escape).
  - `MetadataBuildSchemaTree(...)` for deterministic schema-tree shaping with per-path dedup and terminal-node flags.
- Preserved existing metadata SQL helper constants/accessors (`sys.schemas`, `sys.tables`, `sys.columns`, indexes, constraints, routines).
- Added metadata collection normalization + query resolution helpers:
  - `NormalizeMetadataCollectionName(...)`
  - `ResolveMetadataCollectionQuery(...)`
  - Collection aliases now cover catalog/key/privilege/type families.
- Added driver-level metadata execution API surface on the connection:
  - `Conn.QueryMetadata(ctx, collection)` resolves the metadata collection and executes it through the native query path.
  - `Conn.QueryMetadataWithRestrictions(ctx, collection, restrictions)` provides first-class metadata restriction filtering without altering non-metadata query paths.
  - Unsupported collections return structured `ErrNotSupported` (`SQLSTATE 0A000`).
- Added metadata restriction filtering in `metadata.go`:
  - Alias-aware key normalization for catalog/schema/table/column/index/constraint/procedure/function/type families.
  - Collection-aware restriction-key scope maps.
  - Driver-side row filtering (`filterMetadataRowsByRestrictions`) with null matching via `"null"` and unknown/unmapped key ignore behavior.
- Added `metadata_rows.go` in-memory `driver.Rows` implementation for filtered metadata results so metadata filtering does not require consumer-side post-processing.
- Added lane-local DSN/config compatibility switch for recursive metadata behavior:
  - New `Config.MetadataExpandSchemaParents` field.
  - New parameter aliases parsed in `applyParam`: `metadata_expand_schema_parents`, `metadataExpandSchemaParents`, `expand_schema_parents`, `expandSchemaParents`, `dbeaver_expand_schema_parents`.
- Added focused lane tests in `metadata_test.go` and `config_test.go` for metadata expansion, pattern behavior, tree shaping, and config alias parsing.
  - Additional tests now cover metadata alias resolution and `Conn.QueryMetadata` routing/rejection behavior.
  - New tests cover restriction alias/null handling and `Conn.QueryMetadataWithRestrictions` wire-path filtering behavior.

## Tests Run
- `cd tracks/alpha/drivers/go && go test ./...`
  - Result: `PASS` (`ok github.com/scratchbird/scratchbird-go`, `ok github.com/scratchbird/scratchbird-go/conformance`)

## META Status Recommendation
- Recommendation: `PARTIAL`
- Covered in lane:
  - Metadata SQL catalog query helpers are present.
  - Metadata alias normalization and query resolver are implemented and tested.
  - Driver-level metadata query APIs (`Conn.QueryMetadata` and `Conn.QueryMetadataWithRestrictions`) are implemented and tested.
  - Restriction-aware metadata filtering is implemented and lane-tested (alias matching, null matching, unknown-key ignore behavior).
  - Recursive schema parent expansion behavior is implemented and unit-tested.
  - Recursive schema tree shaping helper is implemented and unit-tested.
  - Metadata recursion compatibility toggle is parsed from DSN aliases.
- Remaining gaps:
  - No metadata-focused live integration or conformance coverage yet for schema/table/column catalog retrieval and recursive tree output from engine responses.
