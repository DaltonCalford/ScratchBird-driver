# Swift Driver Checklist

## P0 (Blocking)

- [x] Implement TLS transport in `swift/Sources/ScratchBird/Socket.swift`. Issue: TBD
- [x] Enforce binary-only (reject `binary_transfer=false`) in `swift/Sources/ScratchBird/Connection.swift`. Issue: TBD
- [x] Reject `compression=zstd` until server support exists in `swift/Sources/ScratchBird/Connection.swift`. Issue: TBD

## P1 (Core)

- [x] Add array encoding/decoding in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [x] Add composite encoding/decoding in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [x] Add range encoding/decoding in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [x] Add inet/cidr/macaddr encode/decode in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [x] Add vector literal encode/decode in `swift/Sources/ScratchBird/Types.swift`. Issue: TBD
- [x] Add sys.* metadata helpers in `swift/Sources/ScratchBird/Metadata.swift`. Issue: TBD

## P2 (Follow-ups)

- [x] Add conformance/integration tests in `swift/Tests/`. Issue: TBD

## P3 (Future)
