# Mojo Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [ ] Replace Python bridge with native SBWP client in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Progress: `src/scratchbird.mojo` now compiles in current Mojo syntax as a facade over `src/scratchbird_native.mojo`, with deterministic module-surface smoke in `tests/scratchbird_surface.mojo`; native bootstrap coverage in `tests/native_bootstrap.mojo` now includes connect/ping guards, metadata alias/query resolution plus executable metadata rowcount helpers, transaction lifecycle guard/no-op semantics, savepoint lifecycle guards (`25000`/`3B001`), prepare-bind mismatch handling, prepared execute parity, paging-query rowcount semantics, stream/cancel with post-cancel recovery smoke, deterministic SQLSTATE-prefixed native guard/unsupported error strings, and active lifecycle hooks for circuit-breaker/keepalive/telemetry plus leak-detector/pipeline scaffolds. Integration/conformance launchers (`tracks/alpha/drivers/mojo/tests/integration.py`, `tracks/alpha/drivers/mojo/tests/sbdriver_conformance.py`) now run both `scratchbird_surface.mojo` and `native_bootstrap.mojo` before shim smoke, and integration/conformance default to deterministic non-skipping direct/manager/bad-auth execution when corresponding URL env vars are unset; bridge-shim parity still carries prepare/txn/ping/savepoint helpers for deterministic harness coverage. Full wire-level transport cutover remains open.
- [x] Enforce TLS required and binary-only guard rails in current bridge shim (`tracks/alpha/drivers/mojo/src/scratchbird.py`) with deterministic tests in `tracks/alpha/drivers/mojo/tests/connection_guards.py`. Issue: DONE (2026-03-05)
- [x] Reject `compression=zstd` until server support exists (`tracks/alpha/drivers/mojo/src/scratchbird.py`) with deterministic tests in `tracks/alpha/drivers/mojo/tests/connection_guards.py`. Issue: DONE (2026-03-05)

## P1 (Core)

- [x] Implement bridge-shim type encode/decode wrappers in `tracks/alpha/drivers/mojo/src/scratchbird.py` with deterministic tests in `tracks/alpha/drivers/mojo/tests/type_codecs.py`. Issue: DONE (2026-03-05)
- [x] Expand bridge-shim type support to composite/geometry/inet-cidr-macaddr (`tracks/alpha/drivers/mojo/src/scratchbird.py`) with deterministic coverage in `tracks/alpha/drivers/mojo/tests/type_codecs.py`. Issue: DONE (2026-03-05)
- [x] Add sys.* metadata helpers in bridge lane (`tracks/alpha/drivers/mojo/src/scratchbird.py`) with alias/query coverage in `tracks/alpha/drivers/mojo/tests/metadata_execution.py`. Issue: DONE (2026-03-05)

## P2 (Follow-ups)

- [x] Add conformance/integration coverage for bridge lane (`tracks/alpha/drivers/mojo/tests/sbdriver_conformance.py`, `tracks/alpha/drivers/mojo/tests/integration.py`, `tracks/alpha/drivers/mojo/tests/connection_guards.py`). Issue: DONE (2026-03-05)

## P3 (Future)
