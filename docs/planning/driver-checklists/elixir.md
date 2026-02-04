# Elixir Driver Checklist

## P0 (Blocking)

- [ ] Enforce TLS required (reject `sslmode=disable`) in `elixir/lib/scratchbird/connection.ex`. Issue: TBD
- [ ] Enforce binary-only (reject `binary_transfer=false`) in `elixir/lib/scratchbird/connection.ex`. Issue: TBD
- [ ] Reject `compression=zstd` until server support exists in `elixir/lib/scratchbird/connection.ex`. Issue: TBD

## P1 (Core)

- [ ] Add array encoding/decoding in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [ ] Add composite encoding/decoding in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [ ] Add vector literal encode/decode in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [ ] Add inet/cidr/macaddr encode/decode in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [ ] Add sys.* metadata helpers in `elixir/lib/scratchbird/metadata.ex` and export from `elixir/lib/scratchbird.ex`. Issue: TBD
- [ ] Add SQLSTATE class-prefix mapping in `elixir/lib/scratchbird/errors.ex`. Issue: TBD

## P2 (Follow-ups)

- [ ] Add conformance/integration tests in `elixir/test/`. Issue: TBD
