# Ruby Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `ruby/lib/scratchbird/errors.rb`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: Conform to Ruby DBI expectations for prepared statements and fetch loops. (Source: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Constraint: Ensure exceptions expose SQLSTATE and map to DBI error subclasses. (Source: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Constraint: Use UTF-8 encoding for all textual fields. (Source: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Test: Validate `DBI::StatementHandle#fetch` and `#finish` behavior under errors. (Source: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Test: Confirm `DBI::Database#ping` returns appropriate errors on dropped connections. (Source: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Constraint: Rails uses `config/database.yml` for connection configuration and `ActiveRecord::Base.establish_connection` semantics. (Source: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Constraint: Migrations must work via `rails db:migrate` and schema dumps must be stable. (Source: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Constraint: Adapter must implement the ActiveRecord adapter interface (quoting, schema, type map). (Source: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Test: Validate schema dumping and reload (`schema.rb`) for all core types. (Source: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Test: Confirm `rails db:migrate` applies and rolls back without metadata drift. (Source: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `ruby/test/`. Issue: TBD
