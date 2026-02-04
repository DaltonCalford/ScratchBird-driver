# Swift Driver Checklist

## P0 (Blocking)

- [ ] Implement TLS transport in `swift/Sources/ScratchBird/Socket.swift`. Issue: TBD
- [ ] Enforce binary-only (reject `binary_transfer=false`) in `swift/Sources/ScratchBird/Connection.swift`. Issue: TBD
- [ ] Reject `compression=zstd` until server support exists in `swift/Sources/ScratchBird/Connection.swift`. Issue: TBD

## P1 (Core)

- [ ] Add array encoding/decoding in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [ ] Add composite encoding/decoding in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [ ] Add range encoding/decoding in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [ ] Add inet/cidr/macaddr encode/decode in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [ ] Add vector literal encode/decode in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [ ] Add sys.* metadata helpers in `swift/Sources/ScratchBird/Metadata.swift`. Issue: TBD

## P2 (Follow-ups)

- [ ] Add conformance/integration tests in `swift/Tests/`. Issue: TBD
