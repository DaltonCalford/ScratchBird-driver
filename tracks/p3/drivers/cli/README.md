# ScratchBird CLI Tools

Native CLI tools for ScratchBird operations and conformance workflows:
`sb_isql`, `sb_admin`, `sb_backup`, `sb_security`, `sb_verify`, and
`sbdriver_conformance`.

## Top-Level Lane Docs

- [`BASELINE_REQUIREMENT_MAPPING.md`](BASELINE_REQUIREMENT_MAPPING.md) - Lane-local S0 mapping of CLI capabilities to JDBCBL requirement groups.
- [CLI user docs](../../../../docs/user-documentation/tools/README.md)
- [Documentation index](../../../../docs/README.md)

## Connection Modes

Network-backed CLIs (`sb_isql`, `sb_admin`, `sb_security`) now support the
current ScratchBird connection protocol surface:

- `--mode=embedded` (mapped to local IPC transport in the current beta C++
  network client implementation)
- `--mode=local-ipc` (`ipc_method` + optional `ipc_path`)
- `--mode=inet` (listener TCP mode)
- `--mode=managed` (manager proxy front-door mode)

Use `--connection=<connection_string>` for full explicit control, or combine
mode flags with `--conn-opt key=value` for additional driver parameters.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build coverage. |
| Windows | Experimental | CI build attempt enabled; verify run status before release. |
| macOS | Untested | Not currently covered in CI. |

## Build

```bash
cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF
cmake --build build_cli --config Release
```

Optional:
- `-DSB_BUILD_CLI_FDW=ON` builds `sb_pg_isql`, `sb_my_isql`, `sb_fb_isql` (requires FDW adapters from the engine repo).

See `docs/BUILD_MATRIX.md` for dependencies.

## Conformance Sample

Lane-local sample manifest and one-command runner:

- Manifest: `conformance/sbwp_conformance_manifest.sample.json`
- Runner: `conformance/run_sbdriver_conformance_sample.sh`
- The adapter now supports manifest-level typed assertions via
  `expect_columns`, `expect_column_type_oids`, `expect_first_row_json`,
  `expect_first_row_types`, and `expect_rows_json`.

Run:

```bash
export SB_CONFORMANCE_DSN="scratchbird://user:pass@localhost:3092/mydb?protocol=native"
tracks/p3/drivers/cli/conformance/run_sbdriver_conformance_sample.sh
```

Optional runner flags:

- `--binary-params` or `--text-params`
- `--manifest <path>`
- `--output <path>`
- `--no-build`
