# Elixir Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [x] Enforce TLS required (reject `sslmode=disable`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: DONE (2026-03-05)
- [x] Enforce binary-only (reject `binary_transfer=false`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: DONE (2026-03-05)
- [x] Reject `compression=zstd` until server support exists in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: DONE (2026-03-05)

## P1 (Core)

- [x] Add array encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: DONE (2026-03-05)
- [x] Add composite encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: DONE (2026-03-05)
- [x] Add vector literal encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: DONE (2026-03-05)
- [x] Add inet/cidr/macaddr encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: DONE (2026-03-05)
- [x] Add sys.* metadata helpers in `tracks/p3/drivers/elixir/lib/scratchbird/metadata.ex` and export from `tracks/p3/drivers/elixir/lib/scratchbird.ex`. Issue: DONE (2026-03-05)
- [x] Add SQLSTATE class-prefix mapping in `tracks/p3/drivers/elixir/lib/scratchbird/errors.ex`. Issue: DONE (2026-03-05)

## P2 (Follow-ups)

- [x] Add conformance/integration tests in `tracks/p3/drivers/elixir/test/`. Issue: DONE (2026-03-05)

## P3 (Future)
