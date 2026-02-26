# ScratchBird CLI Tools

Native CLI tools for ScratchBird operations and conformance workflows:
`sb_isql`, `sb_admin`, `sb_backup`, `sb_security`, `sb_verify`, and
`sbdriver_conformance`.

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
