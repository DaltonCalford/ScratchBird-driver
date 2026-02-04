# Ruby Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/ruby/lib/scratchbird/errors.rb`. Issue: DONE (2026-02-04)


## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Conform to Ruby DBI expectations for prepared statements and fetch loops. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Ensure exceptions expose SQLSTATE and map to DBI error subclasses. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Use UTF-8 encoding for all textual fields. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate `DBI::StatementHandle#fetch` and `#finish` behavior under errors. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm `DBI::Database#ping` returns appropriate errors on dropped connections. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Rails uses `config/database.yml` for connection configuration and `ActiveRecord::Base.establish_connection` semantics. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Migrations must work via `rails db:migrate` and schema dumps must be stable. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Adapter must implement the ActiveRecord adapter interface (quoting, schema, type map). (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate schema dumping and reload (`schema.rb`) for all core types. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm `rails db:migrate` applies and rolls back without metadata drift. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/ruby/test/`. Issue: DONE (2026-02-04) (Sources: ``)
## P3 (Future)
