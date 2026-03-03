# S3 Metadata Implementation (DLB-GO-004)

Scope: `tracks/alpha/drivers/go` lane only.

## Changes
- Added recursive-schema metadata helpers in `metadata.go`:
  - `MetadataExpandSchemaNames(...)` for optional dotted parent expansion with JDBC-style pattern filtering (`%`, `_`, `\\` escape).
  - `MetadataBuildSchemaTree(...)` for deterministic schema-tree shaping with per-path dedup and terminal-node flags.
- Preserved existing metadata SQL helper constants/accessors (`sys.schemas`, `sys.tables`, `sys.columns`, indexes, constraints, routines).
- Added lane-local DSN/config compatibility switch for recursive metadata behavior:
  - New `Config.MetadataExpandSchemaParents` field.
  - New parameter aliases parsed in `applyParam`: `metadata_expand_schema_parents`, `metadataExpandSchemaParents`, `expand_schema_parents`, `expandSchemaParents`, `dbeaver_expand_schema_parents`.
- Added focused lane tests in `metadata_test.go` and `config_test.go` for metadata expansion, pattern behavior, tree shaping, and config alias parsing.

## Tests Run
- `cd tracks/alpha/drivers/go && go test . -run 'TestMetadata|TestParseMetadataExpandSchemaParents'`
  - Result: `PASS` (`ok github.com/scratchbird/scratchbird-go 0.003s`)

## META Status Recommendation
- Recommendation: `PARTIAL`
- Covered in lane:
  - Metadata SQL catalog query helpers are present.
  - Recursive schema parent expansion behavior is implemented and unit-tested.
  - Recursive schema tree shaping helper is implemented and unit-tested.
  - Metadata recursion compatibility toggle is parsed from DSN aliases.
- Remaining gaps:
  - No driver-level metadata execution API surface is exposed through `database/sql` abstractions in this lane.
  - No metadata-focused live integration or conformance coverage yet for schema/table/column catalog retrieval and recursive tree output from engine responses.
