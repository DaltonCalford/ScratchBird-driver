# Tableau Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Tableau uses ODBC or JDBC drivers depending on the connector. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The driver must expose accurate metadata for Tableau's data model. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Large result sets must support paging and cancellation. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Tableau can publish and refresh extracts. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm custom SQL uses parameter binding without errors. | Yes | Deferred | Test criteria from SPECIFICATION.md |
