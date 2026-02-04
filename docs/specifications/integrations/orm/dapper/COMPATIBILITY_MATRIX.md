# Dapper Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Ensure parameter binding supports anonymous objects and `DynamicParameters`. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Dapper multi-mapping (`splitOn`) with joined queries. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Ensure `QueryMultiple` works with multiple result sets. | Yes | Deferred | Test criteria from SPECIFICATION.md |
