# Excel (ODBC) Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Excel uses ODBC data sources and expects DSN configuration via the OS ODBC manager. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The driver must expose stable column types for import. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Result sets should avoid server-side cursor timeouts. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Excel data import and refresh workflows. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm wide tables and large row counts import correctly. | Yes | Deferred | Test criteria from SPECIFICATION.md |
