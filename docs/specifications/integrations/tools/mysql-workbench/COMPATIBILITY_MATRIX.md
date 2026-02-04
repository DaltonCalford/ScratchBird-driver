# MySQL Workbench Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| MySQL Workbench migrations use ODBC drivers for source/target connectivity. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Metadata discovery must support `SQLTables`, `SQLColumns`, and `SQLPrimaryKeys` equivalents. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The driver must tolerate long-running introspection queries. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Workbench migration wizard completes schema introspection. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm data copy works for large tables with paging. | Yes | Deferred | Test criteria from SPECIFICATION.md |
