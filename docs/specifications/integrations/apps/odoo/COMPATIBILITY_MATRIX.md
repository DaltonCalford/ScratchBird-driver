# Odoo Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Odoo requires PostgreSQL and manages databases via a dedicated DB user. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Connection configuration is typically via `odoo.conf`. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Odoo uses large schemas and relies on sequences and constraints. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Odoo database creation and module installation. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm ORM migrations on upgrade. | Yes | Deferred | Test criteria from SPECIFICATION.md |
