# Django ORM Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Django uses `DATABASES` settings for connection configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Migrations are driven by `manage.py migrate`, and schema introspection expects backend features. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The backend adapter must implement Django Database Backend APIs (operations, features, introspection). | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate `inspectdb` output matches metadata contract. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm Django migration operations for indexes and constraints. | Yes | Deferred | Test criteria from SPECIFICATION.md |
