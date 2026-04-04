# Hibernate Dialect API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_contract_only`
- Best-in-class benchmark: `Hibernate PostgreSQLDialect`
- Authoritative lane spec: `docs/application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/hibernate.md`
- Remaining gap summary: The dialect is contract-first today; full validated runtime ORM and migration behavior is still server-blocked.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md`
- Track root: `tracks/alpha/integrations/scratchbird-hibernate-dialect`
- Later verification packet: `../development/server-verification/hibernate.md`

## Integration Surface

- benchmark target: `Hibernate PostgreSQLDialect`
- current state: `partial_contract_only`

## Required Integration Families

- freeze dialect registration, ORM lifecycle, DDL compilation, and migration acceptance gates
- require live ORM bootstrap and schema-management evidence

## Remaining Server-Blocked Validation

- current lane is still contract-first rather than fully validated runtime integration
- schema-management, migration, and ORM lifecycle proof remain server-blocked
