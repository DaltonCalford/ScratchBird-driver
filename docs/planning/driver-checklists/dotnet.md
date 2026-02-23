# .NET Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/dotnet/src/ScratchBird.Data/Errors.cs`. Issue: Closed (2026-02-23)

### Integration Appendix Tasks

- [x] Constraint: ADO.NET patterns rely on DbConnection, DbCommand, DbDataReader. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Providers should support DbProviderFactory usage. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate DbDataReader schema metadata. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm DbException SQLSTATE mapping. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: EF Core uses LINQ and database providers to translate queries. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Provider versions must align with EF Core major versions. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate LINQ translation for common filters. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify provider version compatibility and migrations. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Ensure parameter binding supports anonymous objects and `DynamicParameters`. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Dapper multi-mapping (`splitOn`) with joined queries. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Ensure `QueryMultiple` works with multiple result sets. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/dotnet/tests/`. Issue: DONE (2026-02-04) (Sources: ``)
## P3 (Future)
