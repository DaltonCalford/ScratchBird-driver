# Superset Driver

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
- API/reference: `../api-reference/superset.md`

## Build / Install

- `cd tracks/beta/integrations/scratchbird-superset-driver`
- `python -m pip install -e ".[tooling,superset]"`

## Later Verification Inputs

- `SCRATCHBIRD_TEST_DSN`

## Later Verification Commands

- `python -m pytest`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
