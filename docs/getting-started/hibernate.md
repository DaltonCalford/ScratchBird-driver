# Hibernate Dialect

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
- API/reference: `../api-reference/hibernate.md`

## Build / Install

- `cd tracks/alpha/integrations/scratchbird-hibernate-dialect`

## Later Verification Inputs

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

## Later Verification Commands

- `mvn test`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
