# DBeaver Extension API / Integration Reference

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
- Track root: `tracks/alpha/integrations/scratchbird-dbeaver-driver`
- Later verification packet: `../development/server-verification/dbeaver.md`

## Integration Surface

- benchmark target: `DBeaver PostgreSQL extension`
- current state: `partial_plugin`

## Required Integration Families

- freeze plugin packaging, update-site install, schema-tree behavior, and editor metadata expectations
- require DBeaver-side UI and navigator goldens in release evidence

## Remaining Server-Blocked Validation

- UI plugin packaging and update-site installation proof remain open
- schema navigator, editor payload, and query-preview behavior need later live validation
