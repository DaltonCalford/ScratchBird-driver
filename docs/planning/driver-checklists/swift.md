# Swift Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [x] Implement TLS transport in `tracks/beta/drivers/swift/Sources/ScratchBird/Socket.swift`. Issue: Complete (2026-02-23)
- [x] Enforce binary-only (reject `binary_transfer=false`) in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Complete (2026-02-23)
- [x] Reject `compression=zstd` until server support exists in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Complete (2026-02-23)

## P1 (Core)

- [x] Add array encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete (2026-03-03)
- [x] Add composite encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete (2026-03-03)
- [x] Add range encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete (2026-03-03)
- [x] Add inet/cidr/macaddr encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete (2026-03-03)
- [x] Add vector literal encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`. Issue: Complete (2026-03-03)
- [x] Add sys.* metadata helpers in `tracks/beta/drivers/swift/Sources/ScratchBird/Metadata.swift`. Issue: Complete (2026-03-03)
- [x] Add client-facing metadata execution wrappers and schema-tree accessors in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`. Issue: Complete (2026-03-04)
- [x] Add typed wire-error mapping (SQLSTATE class/exact-state) in `tracks/beta/drivers/swift/Sources/ScratchBird/Errors.swift` and `tracks/beta/drivers/swift/Sources/ScratchBird/Protocol.swift`. Issue: Complete (2026-03-04)

## P2 (Follow-ups)

- [x] Add deterministic conformance/unit tests in `tracks/beta/drivers/swift/Tests/` for TXN/EXEC validation, recursive metadata shaping, codec parity, and typed wire-error mapping. Issue: Complete (2026-03-04)
- [ ] Add live handshake/TXN/EXEC/error/resilience integration tests in `tracks/beta/drivers/swift/Tests/` (env-gated) to close remaining parity gaps. Issue: Open

## P3 (Future)
