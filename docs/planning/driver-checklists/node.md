# Node.js Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/node/src/errors.ts`. Issue: DONE (2026-02-04)

### Integration Appendix Tasks

- [x] Constraint: Parameterized queries use positional placeholders and value arrays. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Prepared statements are often represented by named query configs. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate parameter binding conversion rules for arrays and objects. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm prepared statement name reuse behavior. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Sequelize requires explicit DataTypes for model attributes. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: DataTypes support varies by dialect; JSON/JSONB have differing support. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate DataTypes mapping for JSON/JSONB and string types. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify nullability defaults. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Prisma expects a `datasource` and `generator` in `schema.prisma` with a connection URL. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Support introspection flows (similar to `prisma db pull`) and migrations (similar to `prisma migrate`). (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Ensure scalar types map cleanly to Prisma field types and `@db` native types. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate introspection against a schema with enums, arrays, and JSON. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Ensure Prisma Client queries return correct nullability and enum mappings. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Support TypeORM `DataSource` configuration and `DataSourceOptions` fields (host, port, database, username, password, ssl). (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Ensure metadata helpers provide table/column info for entity synchronization. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Avoid relying on TypeORM `synchronize` for production migrations. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate entity metadata discovery for `@Entity` with custom schema. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify parameterized queries use positional `$1` or named bindings as expected by the driver. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/node/test/`. Issue: DONE (2026-02-04) (Sources: ``)
## P3 (Future)
