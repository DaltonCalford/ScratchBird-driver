# Dart Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [x] Enforce TLS required (reject `sslmode=disable`) in `tracks/beta/drivers/dart/lib/src/client.dart`. Issue: DONE (2026-03-04)
- [x] Enforce binary-only (reject `binary_transfer=false`) in `tracks/beta/drivers/dart/lib/src/client.dart` or `tracks/beta/drivers/dart/lib/src/config.dart`. Issue: DONE (2026-03-04)
- [x] Reject `compression=zstd` until server support exists in `tracks/beta/drivers/dart/lib/src/client.dart`. Issue: DONE (2026-03-04)

## P1 (Core)

- [x] Add array encoding/decoding in `tracks/beta/drivers/dart/lib/src/types.dart`. Issue: DONE (2026-03-04)
- [x] Add composite encoding/decoding in `tracks/beta/drivers/dart/lib/src/types.dart`. Issue: DONE (2026-03-04)
- [x] Add vector literal encode/decode in `tracks/beta/drivers/dart/lib/src/types.dart`. Issue: DONE (2026-03-04)
- [x] Add inet/cidr/macaddr encode/decode in `tracks/beta/drivers/dart/lib/src/types.dart`. Issue: DONE (2026-03-04)
- [x] Add sys.* metadata helpers in `tracks/beta/drivers/dart/lib/src/metadata.dart` and export via `tracks/beta/drivers/dart/lib/scratchbird.dart`. Issue: DONE (2026-03-04)

## P2 (Follow-ups)

- [ ] Add conformance/integration tests in `tracks/beta/drivers/dart/test/`. Issue: Open

## P3 (Future)
