# .NET Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: ADO.NET patterns rely on DbConnection, DbCommand, DbDataReader. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Constraint: Providers should support DbProviderFactory usage. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Test: Validate DbDataReader schema metadata. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Test: Confirm DbException SQLSTATE mapping. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)
- [ ] Constraint: EF Core uses LINQ and database providers to translate queries. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Constraint: Provider versions must align with EF Core major versions. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Test: Validate LINQ translation for common filters. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
- [ ] Test: Verify provider version compatibility and migrations. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Constraint: Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Constraint: Ensure parameter binding supports anonymous objects and `DynamicParameters`. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Test: Validate Dapper multi-mapping (`splitOn`) with joined queries. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Test: Ensure `QueryMultiple` works with multiple result sets. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)
- [ ] Add conformance tests for full type matrix in `tracks/alpha/drivers/dotnet/tests/`. Issue: TBD (Sources: ``)
## P3 (Future)