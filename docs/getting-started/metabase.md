# Metabase Plugin

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
- API/reference: `../api-reference/metabase.md`

## Build / Install

- `cd tracks/alpha/integrations/scratchbird-metabase-driver`

## Later Verification Inputs

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

## Later Verification Commands

- `clojure -M:test`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
