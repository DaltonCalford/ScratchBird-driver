# Ruby Driver Checklist

## P1 (Core)
- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `ruby/lib/scratchbird/errors.rb`. Issue: TBD


## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Conform to Ruby DBI expectations for prepared statements and fetch loops. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Constraint: Ensure exceptions expose SQLSTATE and map to DBI error subclasses. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Constraint: Use UTF-8 encoding for all textual fields. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Test: Validate `DBI::StatementHandle#fetch` and `#finish` behavior under errors. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Test: Confirm `DBI::Database#ping` returns appropriate errors on dropped connections. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)
- [ ] Constraint: Rails uses `config/database.yml` for connection configuration and `ActiveRecord::Base.establish_connection` semantics. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Constraint: Migrations must work via `rails db:migrate` and schema dumps must be stable. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Constraint: Adapter must implement the ActiveRecord adapter interface (quoting, schema, type map). (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Test: Validate schema dumping and reload (`schema.rb`) for all core types. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Test: Confirm `rails db:migrate` applies and rolls back without metadata drift. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)
- [ ] Add conformance tests for full type matrix in `ruby/test/`. Issue: TBD

## P3 (Future)
