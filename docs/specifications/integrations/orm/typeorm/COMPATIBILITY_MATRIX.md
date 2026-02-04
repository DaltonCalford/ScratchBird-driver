# TypeORM Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Support TypeORM `DataSource` configuration and `DataSourceOptions` fields (host, port, database, username, password, ssl). | Yes | Deferred | Constraint from SPECIFICATION.md |
| Ensure metadata helpers provide table/column info for entity synchronization. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Avoid relying on TypeORM `synchronize` for production migrations. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate entity metadata discovery for `@Entity` with custom schema. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Verify parameterized queries use positional `$1` or named bindings as expected by the driver. | Yes | Deferred | Test criteria from SPECIFICATION.md |
