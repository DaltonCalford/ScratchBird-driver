# Rails ActiveRecord Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Rails uses `config/database.yml` for connection configuration and `ActiveRecord::Base.establish_connection` semantics. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Migrations must work via `rails db:migrate` and schema dumps must be stable. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Adapter must implement the ActiveRecord adapter interface (quoting, schema, type map). | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate schema dumping and reload (`schema.rb`) for all core types. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm `rails db:migrate` applies and rolls back without metadata drift. | Yes | Deferred | Test criteria from SPECIFICATION.md |
