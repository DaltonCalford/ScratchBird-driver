# .NET Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `dotnet/src/ScratchBird.Data/Errors.cs`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: ADO.NET patterns rely on DbConnection, DbCommand, DbDataReader. (Source: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Constraint: Providers should support DbProviderFactory usage. (Source: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Test: Validate DbDataReader schema metadata. (Source: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Test: Confirm DbException SQLSTATE mapping. (Source: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Constraint: EF Core uses LINQ and database providers to translate queries. (Source: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Constraint: Provider versions must align with EF Core major versions. (Source: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Test: Validate LINQ translation for common filters. (Source: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Test: Verify provider version compatibility and migrations. (Source: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Constraint: Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection. (Source: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Constraint: Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming. (Source: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Constraint: Ensure parameter binding supports anonymous objects and `DynamicParameters`. (Source: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Test: Validate Dapper multi-mapping (`splitOn`) with joined queries. (Source: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Test: Ensure `QueryMultiple` works with multiple result sets. (Source: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `dotnet/tests/`. Issue: TBD
