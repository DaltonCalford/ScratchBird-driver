# CLI Tooling API Reference

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

## Tools

- `sb_isql`
- `sb_admin`
- `sb_backup`
- `sb_security`
- `sb_verify`
- `sbdriver_conformance`

## Core Expectations

- deterministic exit codes for scripting
- interactive and non-interactive SQL execution
- metadata and introspection helpers
- import/export and copy-style workflows
- stable text and automation-friendly output modes
