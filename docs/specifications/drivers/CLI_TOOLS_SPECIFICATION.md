# ScratchBird CLI Tools Specification

Date: 2026-04-03
Status: Draft - Implementation Ready

Selected benchmark: `psql`

## Scope

This specification covers `sb_isql`, `sb_admin`, `sb_backup`,
`sb_security`, `sb_verify`, and `sbdriver_conformance`.

## Competitive Target

`psql` is the benchmark for interactive SQL, scripting,
import/export, transaction control, metadata inspection, output
formatting, and automation ergonomics.

## Mandatory Closure Areas

- Create a first-class CLI tools specification covering command surface, scripting, output modes, and copy/import/export semantics.
- Make benchmarked script execution, formatting, and metadata tasks part of Beta 1 release evidence.


## Required Capabilities

- interactive SQL shell with scripting mode parity
- explicit transaction and savepoint control
- rich metadata/introspection commands
- import/export and copy-style workflows
- multiple output formats suitable for automation
- deterministic diagnostics and exit codes
- Linux, Windows, and macOS packaging guidance

## Release Evidence

- contract tests for command parsing and execution
- metadata/introspection golden outputs
- scripting and exit-code conformance tests
- benchmark numbers for bulk output and script execution
- packaging/install validation across supported platforms

<!-- cli-server-independent-closure:start -->

## Competitive Closure Status

- Selected benchmark: `psql`
- Current state: `tooling_partial`
- Track root: `tracks/p3/drivers/cli`

Competitive closure targets:

- freeze psql-class scripting, copy/import/export, metadata inspection, and output-format behavior
- require script-execution and exit-code evidence in the release pack

Remaining implementation or proof deltas:

- tooling lane remains partial on TXN, META, TYPE, and RES in the lane-local mapping
- later work is focused on live metadata goldens, script-mode validation, and command-surface proof

## Release Evidence And Later Verification

Release evidence path:

- `release/readiness/cli/<version>/`

Shared evidence templates:

- `docs/development/release-evidence/README.md`

Later server-verification packet:

- `docs/development/server-verification/cli.md`

Required environment inputs:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

Build/bootstrap commands:

- `cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF`
- `cmake --build build_cli --config Release`

Verification commands:

- `ctest --test-dir build_cli --output-on-failure`
- `build_cli/sbdriver_conformance --help`

<!-- cli-server-independent-closure:end -->
