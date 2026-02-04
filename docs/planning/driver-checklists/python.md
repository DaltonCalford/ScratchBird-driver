# Python Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `python/src/scratchbird/connection.py`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: PEP 249 defines standard exceptions and `cursor.description` structure. (Source: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)
- [ ] Constraint: Autocommit should default off; rollback/commit must be exposed. (Source: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)
- [ ] Test: Validate PEP 249 compliance (apilevel, threadsafety, paramstyle). (Source: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)
- [ ] Test: Confirm SQLSTATE mapping and error class raising. (Source: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)
- [ ] Constraint: LangChain SQL integrations expect SQLAlchemy-style connection URIs. (Source: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)
- [ ] Constraint: Query results are consumed by chains that expect consistent column naming. (Source: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)
- [ ] Constraint: Parameter binding must be compatible with SQLAlchemy engine conventions. (Source: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)
- [ ] Test: Validate schema introspection and sample query execution. (Source: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)
- [ ] Test: Confirm long-running queries can be cancelled by the chain. (Source: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)
- [ ] Constraint: Vector APIs expect fixed-dimension vector columns and similarity operators. (Source: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)
- [ ] Constraint: Index choices (HNSW/IVF) can affect performance and accuracy tradeoffs. (Source: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)
- [ ] Constraint: Distance functions must be deterministic and numeric-safe. (Source: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)
- [ ] Test: Validate vector insert/update and top-k similarity queries. (Source: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)
- [ ] Test: Confirm index build time and recall thresholds. (Source: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)
- [ ] Constraint: Haystack document stores expect consistent schema and efficient filter predicates. (Source: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)
- [ ] Constraint: SQL-backed document stores require parameterized queries and transaction safety. (Source: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)
- [ ] Constraint: Embedding/vector fields must preserve dimensionality and order. (Source: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)
- [ ] Test: Validate insert/update/delete for documents with metadata filters. (Source: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)
- [ ] Test: Confirm vector similarity queries return stable ordering. (Source: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)
- [ ] Constraint: Odoo requires PostgreSQL and manages databases via a dedicated DB user. (Source: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)
- [ ] Constraint: Connection configuration is typically via `odoo.conf`. (Source: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)
- [ ] Constraint: Odoo uses large schemas and relies on sequences and constraints. (Source: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)
- [ ] Test: Validate Odoo database creation and module installation. (Source: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)
- [ ] Test: Confirm ORM migrations on upgrade. (Source: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)
- [ ] Constraint: SQLAlchemy Inspector.get_columns returns dicts with keys like name, type, nullable, default, and autoincrement. (Source: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)
- [ ] Constraint: Dialect reflection must support schema-qualified inspection. (Source: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)
- [ ] Test: Validate reflection metadata keys (name/type/nullable/default). (Source: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)
- [ ] Test: Verify schema-qualified inspection. (Source: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)
- [ ] Constraint: Django uses `DATABASES` settings for connection configuration. (Source: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)
- [ ] Constraint: Migrations are driven by `manage.py migrate`, and schema introspection expects backend features. (Source: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)
- [ ] Constraint: The backend adapter must implement Django Database Backend APIs (operations, features, introspection). (Source: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)
- [ ] Test: Validate `inspectdb` output matches metadata contract. (Source: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)
- [ ] Test: Confirm Django migration operations for indexes and constraints. (Source: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `python/tests/`. Issue: TBD
