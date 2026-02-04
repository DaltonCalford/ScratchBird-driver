# Python Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

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

- [x] Constraint: LangChain SQL integrations expect SQLAlchemy-style connection URIs. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Query results are consumed by chains that expect consistent column naming. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Parameter binding must be compatible with SQLAlchemy engine conventions. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate schema introspection and sample query execution. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm long-running queries can be cancelled by the chain. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Vector APIs expect fixed-dimension vector columns and similarity operators. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Index choices (HNSW/IVF) can affect performance and accuracy tradeoffs. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Distance functions must be deterministic and numeric-safe. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate vector insert/update and top-k similarity queries. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm index build time and recall thresholds. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Haystack document stores expect consistent schema and efficient filter predicates. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: SQL-backed document stores require parameterized queries and transaction safety. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Embedding/vector fields must preserve dimensionality and order. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate insert/update/delete for documents with metadata filters. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm vector similarity queries return stable ordering. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
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
