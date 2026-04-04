# DBeaver Extension

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_plugin`
- Best-in-class benchmark: `DBeaver PostgreSQL extension`
- Authoritative lane spec: `docs/application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/dbeaver.md`
- Remaining gap summary: UI plugin packaging, update-site installation, and live workbench validation remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md`
- API/reference: `../api-reference/dbeaver.md`

## Build / Install

- `cd tracks/alpha/integrations/scratchbird-dbeaver-driver`
- `mvn test`

## Later Verification Inputs

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`

## Later Verification Commands

- `mvn -pl test/org.jkiss.dbeaver.ext.scratchbird.test test`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
