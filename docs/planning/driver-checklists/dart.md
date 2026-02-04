# Dart Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [x] Enforce TLS required (reject `sslmode=disable`) in `dart/lib/src/client.dart`. Issue: TBD
- [x] Enforce binary-only (reject `binary_transfer=false`) in `dart/lib/src/client.dart` or `dart/lib/src/config.dart`. Issue: TBD
- [x] Reject `compression=zstd` until server support exists in `dart/lib/src/client.dart`. Issue: TBD

## P1 (Core)

- [x] Add array encoding/decoding in `dart/lib/src/types.dart`. Issue: TBD
- [x] Add composite encoding/decoding in `dart/lib/src/types.dart`. Issue: TBD
- [x] Add vector literal encode/decode in `dart/lib/src/types.dart`. Issue: TBD
- [x] Add inet/cidr/macaddr encode/decode in `dart/lib/src/types.dart`. Issue: TBD
- [x] Add sys.* metadata helpers in `dart/lib/src/metadata.dart` and export via `dart/lib/scratchbird.dart`. Issue: TBD

## P2 (Follow-ups)

- [x] Add conformance/integration tests in `dart/test/`. Issue: TBD

## P3 (Future)