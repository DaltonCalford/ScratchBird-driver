# Metadata Contract Audit (sys.* / JDBC / ODBC)

Status: Draft
Last Updated: 2026-02-04

## Scope

Audited metadata behavior against:
- `docs/specifications/METADATA_SCHEMA_CONTRACT.md`
- `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`
- ScratchBird server view schemas in `ScratchBird/src/catalog/sys_catalog.cpp`

## Summary

- Core language drivers now expose sys.* metadata helpers (schemas/tables/columns).
- ODBC metadata mappings are aligned to sys.* and information_schema.
- Superset/Metabase still need alignment with the finalized sys.columns/sys.index_columns schemas.
- Dart/Swift/Elixir/Mojo do not provide metadata helper APIs yet.

## Evidence (Selected)

- Go: `tracks/alpha/drivers/go/metadata.go`
- Node: `tracks/alpha/drivers/node/src/metadata.ts`
- Python: `tracks/alpha/drivers/python/src/scratchbird/metadata.py`
- Ruby: `tracks/alpha/drivers/ruby/lib/scratchbird/metadata.rb`
- Rust: `tracks/alpha/drivers/rust/src/metadata.rs`
- PHP: `tracks/alpha/drivers/php/src/Metadata.php`
- R: `tracks/beta/drivers/r/R/metadata.R`
- Pascal: `tracks/alpha/drivers/pascal/src/ScratchBird.Metadata.pas`
- .NET: `tracks/alpha/drivers/dotnet/src/ScratchBird.Data/Metadata.cs`
- JDBC: `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBDatabaseMetaData.java`
- ODBC: `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`

## Open Gaps

1. Dart: add sys.* metadata helpers.
2. Swift: add sys.* metadata helpers.
3. Elixir: add sys.* metadata helpers.
4. Mojo: add sys.* metadata helpers (native).
5. Superset: use `sys.columns.data_type_name` directly in `get_columns`.
6. Metabase: revalidate feature flags vs JDBC metadata coverage.
