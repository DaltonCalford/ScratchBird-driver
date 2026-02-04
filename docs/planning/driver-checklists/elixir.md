# Elixir Driver Checklist

## P0 (Blocking)

- [x] Enforce TLS required (reject `sslmode=disable`) in `elixir/lib/scratchbird/connection.ex`. Issue: TBD
- [x] Enforce binary-only (reject `binary_transfer=false`) in `elixir/lib/scratchbird/connection.ex`. Issue: TBD
- [x] Reject `compression=zstd` until server support exists in `elixir/lib/scratchbird/connection.ex`. Issue: TBD

## P1 (Core)

- [x] Add array encoding/decoding in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [x] Add composite encoding/decoding in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [x] Add vector literal encode/decode in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [x] Add inet/cidr/macaddr encode/decode in `elixir/lib/scratchbird/types.ex`. Issue: TBD
- [x] Add sys.* metadata helpers in `elixir/lib/scratchbird/metadata.ex` and export from `elixir/lib/scratchbird.ex`. Issue: TBD
- [x] Add SQLSTATE class-prefix mapping in `elixir/lib/scratchbird/errors.ex`. Issue: TBD

## P2 (Follow-ups)

- [x] Add conformance/integration tests in `elixir/test/`. Issue: TBD
