# ScratchBird Mojo Driver

Native ScratchBird driver lane for Mojo (SBWP v1.1).

Current implementation is a Mojo-Python interop lane:
- API/runtime shim in `src/scratchbird.py`
- Mojo entrypoints in `tests/*.mojo` invoke paired Python scripts for execution
  under the active Mojo toolchain

## Lane Docs

- [Baseline Requirement Mapping (S0)](BASELINE_REQUIREMENT_MAPPING.md)
- [S2 TXN/EXEC Implementation](S2_TXN_EXEC_IMPLEMENTATION.md)
- [S3 Metadata Implementation](S3_METADATA_IMPLEMENTATION.md)
- [Tests](tests/README.md)

## Status

- Full SBWP v1.1 API surface is represented in-lane through the Python-backed shim.
- Mojo wrappers and test adapter now execute under pixi-managed Mojo toolchains.
- Native bootstrap module in current Mojo syntax is available at `src/scratchbird_native.mojo` and validated by `tests/native_bootstrap.mojo`.
- Native Mojo transport/auth remains future work.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Experimental | Validated with pixi-managed Mojo toolchain. |
| Windows | Not supported | No CI/toolchain path configured. |
| macOS | Not supported | No CI/toolchain path configured. |

## Requirements

- Python 3.10+
- Mojo toolchain (recommended: `pixi` workspace at `~/mojo-work/sb-mojo`)

## Verification

From `tracks/alpha/drivers/mojo`:

```bash
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src tests/native_bootstrap.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_recursive_schema.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/txn_exec_parity.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/errors.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/type_codecs.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/connection_guards.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/integration.mojo
tests/sbdriver-conformance --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
```

Optional integration env vars:
- `SCRATCHBIRD_MOJO_URL` for direct smoke
- `SCRATCHBIRD_MOJO_MANAGER_URL` for manager-proxy smoke
- `SCRATCHBIRD_MOJO_BAD_AUTH_URL` for bad-auth smoke (shim-mode deterministic path can append `sb_test_auth_fail=true`)

## Next Steps

- Replace the Python transport bridge with native Mojo sockets/TLS
- Add Mojo-native streaming helpers and type wrappers
