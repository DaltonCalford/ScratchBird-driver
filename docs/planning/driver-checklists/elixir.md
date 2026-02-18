# Elixir Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P0 (Blocking)

- [ ] Enforce TLS required (reject `sslmode=disable`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: Open
- [ ] Enforce binary-only (reject `binary_transfer=false`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: Open
- [ ] Reject `compression=zstd` until server support exists in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`. Issue: Open

## P1 (Core)

- [ ] Add array encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Open
- [ ] Add composite encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Open
- [ ] Add vector literal encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Open
- [ ] Add inet/cidr/macaddr encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`. Issue: Open
- [ ] Add sys.* metadata helpers in `tracks/p3/drivers/elixir/lib/scratchbird/metadata.ex` and export from `tracks/p3/drivers/elixir/lib/scratchbird.ex`. Issue: Open
- [ ] Add SQLSTATE class-prefix mapping in `tracks/p3/drivers/elixir/lib/scratchbird/errors.ex`. Issue: Open

## P2 (Follow-ups)

- [ ] Add conformance/integration tests in `tracks/p3/drivers/elixir/test/`. Issue: Open

## P3 (Future)
