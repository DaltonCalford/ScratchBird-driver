# Qlik Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Qlik Sense uses ODBC connectors and expects DSN-based configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Metadata queries must be performant for script reloads. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Unicode handling must preserve UTF-8 text. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Qlik load script `SELECT` executions. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm reloads handle large tables with paging. | Yes | Deferred | Test criteria from SPECIFICATION.md |
