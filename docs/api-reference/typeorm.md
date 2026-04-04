# TypeORM Adapter API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_contract_only`
- Best-in-class benchmark: `TypeORM PostgreSQL driver`
- Authoritative lane spec: `docs/application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/typeorm.md`
- Remaining gap summary: The adapter is contract-first today; stock driver registry gaps and live runtime validation remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md`
- Track root: `tracks/alpha/integrations/scratchbird-typeorm-adapter`
- Later verification packet: `../development/server-verification/typeorm.md`

## Integration Surface

- benchmark target: `TypeORM PostgreSQL driver`
- current state: `partial_contract_only`

## Required Integration Families

- freeze datasource, migrations, relations, and query-builder acceptance gates against the PostgreSQL driver
- require relation and schema-management evidence

## Remaining Server-Blocked Validation

- current lane is still contract-first rather than fully validated runtime integration
- migrations, relations, and query-builder behavior remain server-blocked
