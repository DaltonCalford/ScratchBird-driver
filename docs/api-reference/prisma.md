# Prisma Adapter API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_contract_only`
- Best-in-class benchmark: `Prisma PostgreSQL connector`
- Authoritative lane spec: `docs/application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/prisma.md`
- Remaining gap summary: The adapter is contract-first today; stock Prisma provider registration and live integration validation remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md`
- Track root: `tracks/alpha/integrations/scratchbird-prisma-adapter`
- Later verification packet: `../development/server-verification/prisma.md`

## Integration Surface

- benchmark target: `Prisma PostgreSQL connector`
- current state: `partial_contract_only`

## Required Integration Families

- freeze datasource, introspection, migration, and native-type acceptance gates
- require runtime and schema workflow validation against the Prisma PostgreSQL connector bar

## Remaining Server-Blocked Validation

- current lane is still contract-first rather than fully validated runtime integration
- introspection, migrations, and runtime query behavior remain server-blocked
