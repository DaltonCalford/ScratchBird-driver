# SQLAlchemy Dialect

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
- API/reference: `../api-reference/sqlalchemy.md`

## Build / Install

- `cd tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`
- `python -m pip install -e ".[tooling]"`

## Later Verification Inputs

- `SCRATCHBIRD_TEST_DSN`

## Later Verification Commands

- `python -m pytest`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
