# Mojo Driver Checklist

## P0 (Blocking)

- [ ] Replace Python bridge with native SBWP client in `mojo/src/scratchbird.mojo`. Issue: TBD
- [ ] Enforce TLS required and binary-only once native transport exists. Issue: TBD
- [ ] Reject `compression=zstd` until server support exists. Issue: TBD

## P1 (Core)

- [ ] Implement SBWP type encoding/decoding wrappers in `mojo/src/scratchbird.mojo`. Issue: TBD
- [ ] Add array, composite, range, geometry, vector, inet/cidr/macaddr support. Issue: TBD
- [ ] Add sys.* metadata helpers in `mojo/src/scratchbird.mojo`. Issue: TBD

## P2 (Follow-ups)

- [ ] Add conformance/integration tests. Issue: TBD
