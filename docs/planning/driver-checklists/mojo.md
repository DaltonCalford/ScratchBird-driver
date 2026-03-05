# Mojo Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [ ] Replace Python bridge with native SBWP client in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Issue: Open
- [x] Enforce TLS required and binary-only guard rails in current bridge shim (`tracks/alpha/drivers/mojo/src/scratchbird.py`) with deterministic tests in `tracks/alpha/drivers/mojo/tests/connection_guards.py`. Issue: DONE (2026-03-05)
- [x] Reject `compression=zstd` until server support exists (`tracks/alpha/drivers/mojo/src/scratchbird.py`) with deterministic tests in `tracks/alpha/drivers/mojo/tests/connection_guards.py`. Issue: DONE (2026-03-05)

## P1 (Core)

- [ ] Implement SBWP type encoding/decoding wrappers in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Issue: Open
- [ ] Add array, composite, range, geometry, vector, inet/cidr/macaddr support. Issue: Open
- [ ] Add sys.* metadata helpers in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Issue: Open

## P2 (Follow-ups)

- [x] Add conformance/integration coverage for bridge lane (`tracks/alpha/drivers/mojo/tests/sbdriver_conformance.py`, `tracks/alpha/drivers/mojo/tests/integration.py`, `tracks/alpha/drivers/mojo/tests/connection_guards.py`). Issue: DONE (2026-03-05)

## P3 (Future)
