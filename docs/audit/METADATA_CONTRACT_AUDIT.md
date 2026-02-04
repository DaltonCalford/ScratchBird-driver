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

- Go: `go/metadata.go`
- Node: `node/src/metadata.ts`
- Python: `python/src/scratchbird/metadata.py`
- Ruby: `ruby/lib/scratchbird/metadata.rb`
- Rust: `rust/src/metadata.rs`
- PHP: `php/src/Metadata.php`
- R: `r/R/metadata.R`
- Pascal: `pascal/src/ScratchBird.Metadata.pas`
- .NET: `dotnet/src/ScratchBird.Data/Metadata.cs`
- JDBC: `jdbc/src/main/java/com/scratchbird/jdbc/SBDatabaseMetaData.java`
- ODBC: `odbc/src/odbc_handles.cpp`

## Open Gaps

1. Dart: add sys.* metadata helpers.
2. Swift: add sys.* metadata helpers.
3. Elixir: add sys.* metadata helpers.
4. Mojo: add sys.* metadata helpers (native).
5. Superset: use `sys.columns.data_type_name` directly in `get_columns`.
6. Metabase: revalidate feature flags vs JDBC metadata coverage.
