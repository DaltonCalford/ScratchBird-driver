# Python Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/python/src/scratchbird/connection.py`. Issue: DONE (2026-03-04)

### Integration Appendix Tasks

- [x] Constraint: PEP 249 defines standard exceptions and `cursor.description` structure. (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Autocommit should default off; rollback/commit must be exposed. (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate PEP 249 compliance (apilevel, threadsafety, paramstyle). (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm SQLSTATE mapping and error class raising. (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: SQLAlchemy Inspector.get_columns returns dicts with keys like name, type, nullable, default, and autoincrement. (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Dialect reflection must support schema-qualified inspection. (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate reflection metadata keys (name/type/nullable/default). (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify schema-qualified inspection. (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Django uses `DATABASES` settings for connection configuration. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Migrations are driven by `manage.py migrate`, and schema introspection expects backend features. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: The backend adapter must implement Django Database Backend APIs (operations, features, introspection). (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate `inspectdb` output matches metadata contract. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm Django migration operations for indexes and constraints. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/python/tests/`. Issue: DONE (2026-02-04) (Sources: ``)
## P3 (Future)

### Integration Appendix Tasks

- [x] Constraint: Odoo requires PostgreSQL and manages databases via a dedicated DB user. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Connection configuration is typically via `odoo.conf`. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Odoo uses large schemas and relies on sequences and constraints. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Odoo database creation and module installation. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm ORM migrations on upgrade. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
