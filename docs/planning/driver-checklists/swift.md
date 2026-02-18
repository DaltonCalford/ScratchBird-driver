# Swift Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [ ] Implement TLS transport in `tracks/beta/drivers/swift/Sources/ScratchBird/Socket.swift`. Issue: Open
- [ ] Enforce binary-only (reject `binary_transfer=false`) in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Open
- [ ] Reject `compression=zstd` until server support exists in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Open

## P1 (Core)

- [ ] Add array encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Open
- [ ] Add composite encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Open
- [ ] Add range encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Open
- [ ] Add inet/cidr/macaddr encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Open
- [ ] Add vector literal encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Open
- [ ] Add sys.* metadata helpers in `tracks/beta/drivers/swift/Sources/ScratchBird/Metadata.swift`. Issue: Open

## P2 (Follow-ups)

- [ ] Add conformance/integration tests in `tracks/beta/drivers/swift/Tests/`. Issue: Open

## P3 (Future)
