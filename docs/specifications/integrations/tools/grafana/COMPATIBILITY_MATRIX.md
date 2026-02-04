# Grafana Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Grafana SQL data sources expect query macros and time-series formatting. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The driver must return correct time column types and ordering. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Connection pooling and query timeouts should be configurable. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate time-series queries return consistent time/value columns. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm dashboard refreshes do not leak connections. | Yes | Deferred | Test criteria from SPECIFICATION.md |
