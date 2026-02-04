# Elixir Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [x] Enforce TLS required (reject `sslmode=disable`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: Complete
- [x] Enforce binary-only (reject `binary_transfer=false`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: Complete
- [x] Reject `compression=zstd` until server support exists in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: Complete

## P1 (Core)

- [x] Add array encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Complete
- [x] Add composite encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Complete
- [x] Add vector literal encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Complete
- [x] Add inet/cidr/macaddr encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Complete
- [x] Add sys.* metadata helpers in `tracks/p3/drivers/elixir/lib/scratchbird/metadata.ex` and export from `tracks/p3/drivers/elixir/lib/scratchbird.ex`. Issue: Complete
- [x] Add SQLSTATE class-prefix mapping in `tracks/p3/drivers/elixir/lib/scratchbird/errors.ex`. Issue: Complete

## P2 (Follow-ups)

- [x] Add conformance/integration tests in `tracks/p3/drivers/elixir/test/`. Issue: Complete

## P3 (Future)
