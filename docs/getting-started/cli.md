# CLI Tooling

<!-- lane-status:start -->
## Current Status

- Lane kind: `tooling`
- Current state: `tooling_partial`
- Best-in-class benchmark: `psql`
- Authoritative lane spec: `docs/specifications/drivers/CLI_TOOLS_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/cli.md`
- Remaining gap summary: Tooling lane remains partial on TXN, META, TYPE, and RES; the remaining work is live metadata/script-mode proof and command-surface validation.
<!-- lane-status:end -->

## Build

```bash
cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF
cmake --build build_cli --config Release
```

## Quick Start

```bash
build_cli/sb_isql scratchbird://user:password@localhost:3092/mydb
build_cli/sbdriver_conformance --help
```

## Current Scope

The CLI lane covers `sb_isql`, `sb_admin`, `sb_backup`, `sb_security`,
`sb_verify`, and `sbdriver_conformance`.

## Environment

Later live verification packets use:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`
