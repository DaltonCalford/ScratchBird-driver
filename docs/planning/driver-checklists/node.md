# Node.js Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `node/src/errors.ts`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: Parameterized queries use positional placeholders and value arrays. (Source: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Constraint: Prepared statements are often represented by named query configs. (Source: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Test: Validate parameter binding conversion rules for arrays and objects. (Source: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Test: Confirm prepared statement name reuse behavior. (Source: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)
- [ ] Constraint: Prisma expects a `datasource` and `generator` in `schema.prisma` with a connection URL. (Source: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Constraint: Support introspection flows (similar to `prisma db pull`) and migrations (similar to `prisma migrate`). (Source: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Constraint: Ensure scalar types map cleanly to Prisma field types and `@db` native types. (Source: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Test: Validate introspection against a schema with enums, arrays, and JSON. (Source: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Test: Ensure Prisma Client queries return correct nullability and enum mappings. (Source: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)
- [ ] Constraint: Sequelize requires explicit DataTypes for model attributes. (Source: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Constraint: DataTypes support varies by dialect; JSON/JSONB have differing support. (Source: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Test: Validate DataTypes mapping for JSON/JSONB and string types. (Source: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Test: Verify nullability defaults. (Source: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)
- [ ] Constraint: Support TypeORM `DataSource` configuration and `DataSourceOptions` fields (host, port, database, username, password, ssl). (Source: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Constraint: Ensure metadata helpers provide table/column info for entity synchronization. (Source: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Constraint: Avoid relying on TypeORM `synchronize` for production migrations. (Source: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Test: Validate entity metadata discovery for `@Entity` with custom schema. (Source: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)
- [ ] Test: Verify parameterized queries use positional `$1` or named bindings as expected by the driver. (Source: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `node/test/`. Issue: TBD
