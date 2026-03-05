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
- `src/scratchbird.mojo` now compiles in current Mojo syntax as a facade over `src/scratchbird_native.mojo`, with deterministic facade smoke in `tests/scratchbird_surface.mojo`.
- Native bootstrap module in current Mojo syntax is available at `src/scratchbird_native.mojo` and validated by `tests/native_bootstrap.mojo`.
- Native bootstrap currently covers deterministic connect/ping guards, extended metadata alias/query resolution, transaction lifecycle guards (`25001` nested begin), savepoint lifecycle guards (`25000`/`3B001`), prepare-bind mismatch handling, prepared execute parity, paging-query rowcount semantics, and stream/cancel (`57014`) with post-cancel recovery semantics.
- Native bootstrap guard and unsupported-operation failures now use deterministic SQLSTATE-prefixed error strings with extractor coverage (`extract_sqlstate`) in lane tests.
- Metadata execution parity now includes deterministic `query_metadata_rows(...)` rowcount helpers in shim/native bootstrap scaffolds.
- Integration and conformance launchers are native-smoke-first (`tests/scratchbird_surface.mojo` then `tests/native_bootstrap.mojo`) with bridge-shim fallback controls.
- Bridge-shim connection parity now includes `prepare`/statement execute plus deterministic `ping`, transaction lifecycle, and savepoint helpers used by lane tests.
- Bridge-shim type codecs now include temporal/json/jsonb/uuid wrappers and array-of-composite encode/decode coverage for deterministic lane testing.
- Lifecycle scaffolds (`circuit_breaker`/`leak_detector`/`keepalive`/`telemetry`/`pipeline`) now compile in current Mojo syntax and have dedicated deterministic smoke coverage in `tests/lifecycle_scaffolds.mojo`.
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
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src tests/scratchbird_surface.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_recursive_schema.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/txn_exec_parity.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/errors.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/type_codecs.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/connection_guards.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src/scratchbird tests/lifecycle_scaffolds.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/integration.mojo
tests/sbdriver-conformance --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
```

Optional launcher env vars:
- `SCRATCHBIRD_MOJO_URL` for direct smoke
- `SCRATCHBIRD_MOJO_MANAGER_URL` for manager-proxy smoke
- `SCRATCHBIRD_MOJO_BAD_AUTH_URL` for bad-auth smoke (shim-mode deterministic path can append `sb_test_auth_fail=true`)
- `SCRATCHBIRD_MOJO_SKIP_NATIVE_BOOTSTRAP` to bypass native smoke (`tests/scratchbird_surface.mojo` and `tests/native_bootstrap.mojo`) in `tests/integration.mojo` and `tests/sbdriver_conformance.py`
- `SCRATCHBIRD_MOJO_NATIVE_REQUIRED` to fail when native bootstrap launcher is unavailable/failing
- `SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN` to require explicit `SCRATCHBIRD_MOJO_URL` / `SCRATCHBIRD_MOJO_MANAGER_URL` / `SCRATCHBIRD_MOJO_BAD_AUTH_URL` for integration/conformance (default lane behavior uses deterministic fallback DSNs)

## Next Steps

- Replace the Python transport bridge with native Mojo sockets/TLS
- Add Mojo-native streaming helpers and type wrappers
