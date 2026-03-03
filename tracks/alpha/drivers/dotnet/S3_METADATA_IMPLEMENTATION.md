# S3 Metadata Implementation (DLB-DOTNET-004)

Scope: `tracks/alpha/drivers/dotnet` lane only.

## Changes

- Added `MetadataExpandSchemaParents` to lane config with JDBC-compatible aliases:
  - `metadataExpandSchemaParents`
  - `metadata_expand_schema_parents`
  - `expandSchemaParents`
  - `expand_schema_parents`
  - `dbeaverExpandSchemaParents`
  - `dbeaver_expand_schema_parents`
- Updated `ScratchBirdConnection.GetSchema` metadata pipeline to:
  - normalize collection keys once;
  - shape metadata rows through a shared helper path;
  - apply restriction filtering for `Tables`, `Columns`, and `Schemas`;
  - optionally expand dotted schema parents for metadata-only recursive tree navigation when `MetadataExpandSchemaParents=true`.
- Added focused metadata shaping tests covering:
  - parent expansion ancestry/uniqueness behavior;
  - expansion + schema-pattern filtering behavior;
  - table/column restriction filtering behavior.
- Added config parser tests verifying metadata parent-expansion aliases.
- Updated `BASELINE_REQUIREMENT_MAPPING.md` `META` row evidence/notes to reflect current behavior.

## Tests Run

- `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~ScratchBirdConnectionMetadataShapingTests"`: **PASS** (4 passed, 0 failed, 0 skipped)
- `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~ScratchBirdConnectionSchemaStatementTests"`: **PASS** (3 passed, 0 failed, 0 skipped)
- `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~ConfigTests.ParseMetadataExpandSchemaParentsAliases"`: **PASS** (1 passed, 0 failed, 0 skipped)

## META Status Recommendation

- Recommendation: **PARTIAL**
- Reason: core metadata shaping improved for recursive schema navigation and restrictions (`Tables`/`Columns`/`Schemas`), but lane metadata coverage is still incomplete versus full JDBC baseline families.

## Remaining Gaps

- Restriction-value handling is currently implemented for `Tables`, `Columns`, and `Schemas` only; other supported collections still use unfiltered row sets.
- Broader metadata families required by JDBC-level parity (for example privilege/key/type-oriented surfaces and fuller DDL-editor fields across all collections) are not fully covered in this lane yet.
- Parent-expanded schema rows are synthetic metadata rows (name-focused) and do not provide physical schema IDs for synthetic ancestors.
