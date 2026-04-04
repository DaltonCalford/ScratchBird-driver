# Metabase Plugin API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_adapter`
- Best-in-class benchmark: `Metabase PostgreSQL driver`
- Authoritative lane spec: `docs/application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/metabase.md`
- Remaining gap summary: Schema sync, field fingerprinting, native-query validation, and packaged plugin proof remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md`
- Track root: `tracks/alpha/integrations/scratchbird-metabase-driver`
- Later verification packet: `../development/server-verification/metabase.md`

## Integration Surface

- benchmark target: `Metabase PostgreSQL driver`
- current state: `partial_adapter`

## Required Integration Families

- freeze schema sync, fingerprinting, native query, and feature-flag behavior against the PostgreSQL driver
- require packaging and sync-performance evidence

## Remaining Server-Blocked Validation

- schema sync, field fingerprinting, and native-query validation remain server-blocked
- packaged plugin/runtime validation remains open
