# SQLAlchemy Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| SQLAlchemy Inspector.get_columns returns dicts with keys like name, type, nullable, default, and autoincrement. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Dialect reflection must support schema-qualified inspection. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate reflection metadata keys (name/type/nullable/default). | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Verify schema-qualified inspection. | Yes | Deferred | Test criteria from SPECIFICATION.md |
