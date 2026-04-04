# Elixir / Ecto Server Verification Packet

Status: server_blocked

## Scope

- lane: `elixir`
- benchmark: `Postgrex`
- current state: `partial`
- track root: `tracks/p3/drivers/elixir`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/elixir`
2. `mix local.hex --force`
3. `mix local.rebar --force`
4. `mix deps.get`

## Verification Commands

1. `mix test`

## Expected Artifacts

- `release/readiness/elixir/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/elixir/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/elixir/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/elixir/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/elixir/<version>/KNOWN_GAPS.md`
- `release/readiness/elixir/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/elixir/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/elixir/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
