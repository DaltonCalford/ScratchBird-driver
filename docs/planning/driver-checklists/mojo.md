# Mojo Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [ ] Replace Python bridge with native SBWP client in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Issue: Open
- [ ] Enforce TLS required and binary-only once native transport exists. Issue: Open
- [ ] Reject `compression=zstd` until server support exists. Issue: Open

## P1 (Core)

- [ ] Implement SBWP type encoding/decoding wrappers in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Issue: Open
- [ ] Add array, composite, range, geometry, vector, inet/cidr/macaddr support. Issue: Open
- [ ] Add sys.* metadata helpers in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`. Issue: Open

## P2 (Follow-ups)

- [ ] Add conformance/integration tests. Issue: Open

## P3 (Future)
