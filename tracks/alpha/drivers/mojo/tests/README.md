# ScratchBird Mojo Tests

This directory contains scaffolding for Mojo conformance and integration
validation against the shared SBWP harness.

## Conformance Adapter (Scaffold)

A minimal `sbdriver-conformance` adapter is provided to wire Mojo into the
shared test harness. It executes `query` tests from the manifest when
`SCRATCHBIRD_MOJO_URL` is set, while `prepare_bind` and `cancel` tests are
currently skipped.

Run (example):

```
export PATH="$PWD/tracks/alpha/drivers/mojo/tests:$PATH"
mojo sbdriver_conformance.mojo --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
sbdriver-conformance --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
```

Environment variables:
- `SCRATCHBIRD_CONFORMANCE_MANIFEST`: optional manifest path
- `SCRATCHBIRD_MOJO_URL`: DSN for running query tests
- `SCRATCHBIRD_MOJO_ENABLE_PREPARE_BIND`: enable prepare/bind tests (requires driver support)
- `SCRATCHBIRD_MOJO_ENABLE_CANCEL`: enable cancel tests (requires driver support)

## Integration Smoke (Scaffold)

`integration.mojo` runs a small set of smoke queries if `SCRATCHBIRD_MOJO_URL`
exists.

```
mojo integration.mojo
```

Notes:
- Requires the ScratchBird Mojo driver module in `tracks/alpha/drivers/mojo/src/`.
- These tests are scaffolds; extend them once parameter binding and cancel are
  implemented in the Mojo driver.
