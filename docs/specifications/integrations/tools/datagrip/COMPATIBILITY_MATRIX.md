# DataGrip Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| DataGrip uses JDBC drivers and requires driver JARs to be configured per data source. | Yes | Deferred | Constraint from SPECIFICATION.md |
| It expects DatabaseMetaData compatibility for schemas, tables, and columns. | Yes | Deferred | Constraint from SPECIFICATION.md |
| SQL dialect quirks must be declared to avoid incorrect SQL generation. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate database introspection for schemas and routines. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm parameterized query execution in the query console. | Yes | Deferred | Test criteria from SPECIFICATION.md |
