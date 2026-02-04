# Hadoop HBase Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| HBase SQL access commonly uses Apache Phoenix with JDBC connectivity. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The driver must handle Phoenix metadata queries and schema discovery. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Upserts and bulk loads require batch-friendly behavior. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Phoenix JDBC metadata reads. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm batch upsert performance with large datasets. | Yes | Deferred | Test criteria from SPECIFICATION.md |
