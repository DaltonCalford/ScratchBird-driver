# Swift Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [x] Implement TLS transport in `tracks/beta/drivers/swift/Sources/ScratchBird/Socket.swift`. Issue: Complete
- [x] Enforce binary-only (reject `binary_transfer=false`) in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Complete
- [x] Reject `compression=zstd` until server support exists in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Complete

## P1 (Core)

- [x] Add array encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete
- [x] Add composite encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete
- [x] Add range encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete
- [x] Add inet/cidr/macaddr encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete
- [x] Add vector literal encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete
- [x] Add sys.* metadata helpers in `tracks/beta/drivers/swift/Sources/ScratchBird/Metadata.swift`. Issue: Complete

## P2 (Follow-ups)

- [x] Add conformance/integration tests in `tracks/beta/drivers/swift/Tests/`. Issue: Complete

## P3 (Future)
