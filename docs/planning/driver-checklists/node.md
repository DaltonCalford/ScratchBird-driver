# Node.js Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: Parameterized queries use positional placeholders and value arrays. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Constraint: Prepared statements are often represented by named query configs. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Test: Validate parameter binding conversion rules for arrays and objects. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Test: Confirm prepared statement name reuse behavior. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Constraint: Sequelize requires explicit DataTypes for model attributes. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Constraint: DataTypes support varies by dialect; JSON/JSONB have differing support. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Test: Validate DataTypes mapping for JSON/JSONB and string types. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Test: Verify nullability defaults. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Prisma expects a `datasource` and `generator` in `schema.prisma` with a connection URL. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Constraint: Support introspection flows (similar to `prisma db pull`) and migrations (similar to `prisma migrate`). (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Constraint: Ensure scalar types map cleanly to Prisma field types and `@db` native types. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Test: Validate introspection against a schema with enums, arrays, and JSON. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Test: Ensure Prisma Client queries return correct nullability and enum mappings. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Constraint: Support TypeORM `DataSource` configuration and `DataSourceOptions` fields (host, port, database, username, password, ssl). (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Constraint: Ensure metadata helpers provide table/column info for entity synchronization. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Constraint: Avoid relying on TypeORM `synchronize` for production migrations. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Test: Validate entity metadata discovery for `@Entity` with custom schema. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Test: Verify parameterized queries use positional `$1` or named bindings as expected by the driver. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Add conformance tests for full type matrix in `node/test/`. Issue: TBD (Sources: ``)
## P3 (Future)