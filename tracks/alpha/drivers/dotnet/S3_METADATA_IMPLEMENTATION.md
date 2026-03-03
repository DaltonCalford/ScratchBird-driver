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
  - apply restriction filtering for `Tables`, `Columns`, `Schemas`, and `Catalogs`;
  - expose additional metadata families (`Catalogs`, `PrimaryKeys`, `ForeignKeys`, `TablePrivileges`, `ColumnPrivileges`, `TypeInfo`);
  - optionally expand dotted schema parents for metadata-only recursive tree navigation when `MetadataExpandSchemaParents=true`.
- Added focused metadata shaping tests covering:
  - parent expansion ancestry/uniqueness behavior;
  - expansion + schema-pattern filtering behavior;
  - table/column restriction filtering behavior;
  - catalog restriction filtering and metadata collection alias normalization.
- Added config parser tests verifying metadata parent-expansion aliases.
- Updated `BASELINE_REQUIREMENT_MAPPING.md` `META` row evidence/notes to reflect current behavior.

## Tests Run

- `dotnet test --filter "FullyQualifiedName~ScratchBirdConnectionMetadataShapingTests"`: **PASS** (8 passed, 0 failed, 0 skipped)
- `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~ScratchBirdConnectionSchemaStatementTests"`: **PASS** (3 passed, 0 failed, 0 skipped)
- `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~ConfigTests.ParseMetadataExpandSchemaParentsAliases"`: **PASS** (1 passed, 0 failed, 0 skipped)

## META Status Recommendation

- Recommendation: **PARTIAL**
- Reason: metadata shaping and family routing are expanded (catalog/key/privilege/type families now available), but deeper restriction-mapping parity and live-metadata integration coverage are still incomplete.

## Remaining Gaps

- Restriction-value handling is still partial across the expanded families (only key collections have explicit mapping rules).
- Metadata field richness for DDL/editor parity is still incomplete in some collections.
- Parent-expanded schema rows are synthetic metadata rows (name-focused) and do not provide physical schema IDs for synthetic ancestors.
