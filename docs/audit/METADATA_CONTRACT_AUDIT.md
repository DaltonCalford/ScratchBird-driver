# Metadata Contract Audit (sys.* / JDBC / ODBC)

Status: Updated
Last Updated: 2026-03-12

## Scope

Audited metadata behavior against:
- `docs/specifications/METADATA_SCHEMA_CONTRACT.md`
- `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`
- ScratchBird server view schemas in `ScratchBird/src/catalog/sys_catalog.cpp`

## Summary

- Core language drivers now expose sys.* metadata helpers
  (schemas/tables/columns).
- ODBC metadata mappings are aligned to sys.* and information_schema.
- JDBC now has explicit closure evidence for resolved-current-schema metadata
  anchoring, metadata family coverage, and pooled-session reset safety.
- Superset and Metabase are now aligned to the finalized sys.columns and
  sys.index_columns surfaces on their supported adapter paths.
- Dart/Swift/Elixir/Mojo do not provide metadata helper APIs yet.

## Evidence (Selected)

- Go: `tracks/p3/drivers/go/metadata.go`
- Node: `tracks/p3/drivers/node/src/metadata.ts`
- Python: `tracks/p3/drivers/python/src/scratchbird/metadata.py`
- Ruby: `tracks/p3/drivers/ruby/lib/scratchbird/metadata.rb`
- Rust: `tracks/p3/drivers/rust/src/metadata.rs`
- PHP: `tracks/p3/drivers/php/src/Metadata.php`
- R: `tracks/p3/drivers/r/R/metadata.R`
- Pascal: `tracks/p3/drivers/pascal/src/ScratchBird.Metadata.pas`
- .NET: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/Metadata.cs`
- JDBC: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBDatabaseMetaData.java`
- JDBC closure tests: `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBJdbcClosureParityTest.java`
- JDBC pooling reset: `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/JDBC203PoolingAndRecoveryContractTest.java`
- ODBC: `tracks/p3/drivers/odbc/src/odbc_handles.cpp`

## Open Gaps

1. Dart: add sys.* metadata helpers.
2. Swift: add sys.* metadata helpers.
3. Elixir: add sys.* metadata helpers.
4. Mojo: add sys.* metadata helpers (native).
