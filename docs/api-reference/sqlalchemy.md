# SQLAlchemy Dialect API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_adapter`
- Best-in-class benchmark: `SQLAlchemy PostgreSQL dialect`
- Authoritative lane spec: `docs/application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/sqlalchemy.md`
- Remaining gap summary: Deep reflection, DDL compilation, Alembic behavior, and packaging evidence remain server-blocked.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md`
- Track root: `tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`
- Later verification packet: `../development/server-verification/sqlalchemy.md`

## Integration Surface

- benchmark target: `SQLAlchemy PostgreSQL dialect`
- current state: `partial_adapter`

## Required Integration Families

- freeze reflection, ORM lifecycle, DDL compilation, and Alembic-facing requirements against the PostgreSQL dialect
- require migration and ORM lifecycle evidence

## Remaining Server-Blocked Validation

- deep reflection, DDL compilation, and Alembic behavior remain server-blocked
- production-grade packaging and benchmark evidence remain open
