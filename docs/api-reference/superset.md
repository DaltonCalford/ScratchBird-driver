# Superset Driver API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_adapter`
- Best-in-class benchmark: `Superset PostgreSQL engine spec`
- Authoritative lane spec: `docs/application-reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/superset.md`
- Remaining gap summary: EngineSpec behavior, SQL Lab validation, deployment packaging, and live query workflows remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md`
- Track root: `tracks/beta/integrations/scratchbird-superset-driver`
- Later verification packet: `../development/server-verification/superset.md`

## Integration Surface

- benchmark target: `Superset PostgreSQL engine spec`
- current state: `partial_adapter`

## Required Integration Families

- freeze EngineSpec, SQL Lab, and deployment expectations against the PostgreSQL engine spec
- require metadata sync, dialect, and packaging evidence

## Remaining Server-Blocked Validation

- EngineSpec behavior, SQL Lab validation, and deployment packaging remain server-blocked
- runtime sync and benchmark evidence remain open
