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
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_recursive_schema.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_execution.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/txn_exec_parity.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/connection_guards.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/integration.mojo
```

Expected behavior:
- metadata and txn/exec tests report `OK`
- integration smoke prints a skip message when `SCRATCHBIRD_MOJO_URL` is not set

## Conformance Adapter

The `sbdriver-conformance` launcher resolves Mojo automatically (prefers pixi
manifest mode) and runs `tests/sbdriver_conformance.mojo`.

```bash
tests/sbdriver-conformance --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
```

Environment variables:
- `SCRATCHBIRD_CONFORMANCE_MANIFEST`: optional manifest path
- `SCRATCHBIRD_MOJO_URL`: DSN for running query tests
- `SCRATCHBIRD_MOJO_ENABLE_PREPARE_BIND`: enable `prepare_bind` tests (requires driver support)
- `SCRATCHBIRD_MOJO_ENABLE_CANCEL`: enable `cancel` tests (requires driver support)

Without `SCRATCHBIRD_MOJO_URL`, conformance tests are reported as skipped.
