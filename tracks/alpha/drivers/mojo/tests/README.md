# ScratchBird Mojo Tests

This lane executes through Mojo entrypoints (`*.mojo`) that delegate to paired
Python test scripts (`*.py`) via Mojo-Python interop.

## Requirements

- Python 3.10+
- `pixi` with Mojo toolchain (default manifest path: `~/mojo-work/sb-mojo`)

Optional environment overrides:
- `MOJO_PIXI_MANIFEST`: path to Mojo pixi workspace used by launcher scripts
- `MOJO_BIN`: explicit Mojo binary (used when pixi manifest is unavailable)

## Quick Run

Run from lane root (`tracks/alpha/drivers/mojo`):

```bash
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src tests/native_bootstrap.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_recursive_schema.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_execution.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/txn_exec_parity.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/errors.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/type_codecs.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/connection_guards.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src/scratchbird tests/lifecycle_scaffolds.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/integration.mojo
```

Expected behavior:
- native bootstrap, metadata, txn/exec, error-propagation, and type-codec tests report `OK` (including native ping, begin/commit/rollback, savepoint lifecycle guards, prepared execute, paging-query rowcount, and post-cancel recovery smoke semantics)
- native bootstrap smoke also validates deterministic SQLSTATE-prefixed guard/unsupported errors via `scratchbird_native.extract_sqlstate(...)`
- metadata execution smoke includes deterministic `query_metadata_rows(...)` rowcount checks in both shim and native bootstrap paths
- lifecycle scaffold test reports `OK` and validates circuit-breaker/leak-detector/keepalive/telemetry/pipeline deterministic behavior under current Mojo syntax
- type-codec suite covers vector/range/composite/geometry/network plus temporal/json/jsonb/uuid and array-of-composite wrappers in the bridge shim
- integration smoke prints skip messages when direct/manager/bad-auth env DSNs are not set

## Conformance Adapter

The `sbdriver-conformance` launcher resolves Mojo automatically (prefers pixi
manifest mode) and runs `tests/sbdriver_conformance.mojo`.

By default, both `sbdriver-conformance` and `integration.py` run the native
bootstrap smoke (`tests/native_bootstrap.mojo`) first, then continue through
the bridge-shim harness path.

Conformance `prepare_bind` checks prefer `connection.prepare(...).execute(...)`
when available and fall back to `connection.query(sql, params)` for older lanes.
Conformance manifest `requires` entries are enforced in-harness; unsupported
requirements are reported as `skipped`.
Conformance defaults to a deterministic lane DSN when `SCRATCHBIRD_MOJO_URL`
is unset, so core tests run as `ok` in local lane runs without external env.
Integration smoke also defaults to deterministic lane DSNs for direct,
manager-proxy, and bad-auth paths when corresponding env vars are unset.

```bash
tests/sbdriver-conformance --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
```

Environment variables:
- `SCRATCHBIRD_CONFORMANCE_MANIFEST`: optional manifest path
- `SCRATCHBIRD_MOJO_URL`: DSN for running query tests
- `SCRATCHBIRD_MOJO_MANAGER_URL`: optional manager-proxy integration DSN
- `SCRATCHBIRD_MOJO_BAD_AUTH_URL`: optional bad-auth integration DSN (for shim tests, append `sb_test_auth_fail=true`)
- `SCRATCHBIRD_MOJO_SKIP_NATIVE_BOOTSTRAP`: optional override to skip native bootstrap smoke in `integration.mojo` / `integration.py` / `sbdriver_conformance.py`
- `SCRATCHBIRD_MOJO_NATIVE_REQUIRED`: optional override to fail launcher smoke when native bootstrap cannot run
- `SCRATCHBIRD_MOJO_ENABLE_PREPARE_BIND`: optional override (defaults enabled; set `0` to disable)
- `SCRATCHBIRD_MOJO_ENABLE_CANCEL`: optional override (defaults enabled; set `0` to disable)
- `SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN`: optional override to require explicit `SCRATCHBIRD_MOJO_URL` (restores skip behavior when URL is unset)

With `SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN=1` and no
`SCRATCHBIRD_MOJO_URL`, conformance tests are reported as skipped.
