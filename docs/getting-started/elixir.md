# Elixir (Ecto) Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `partial`
- Best-in-class benchmark: `Postgrex`
- Authoritative lane spec: `docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/elixir.md`
- Remaining gap summary: Public portal-resume helpers, deterministic stream/paging proof, and transparent in-place reconnect remain incomplete.
<!-- lane-status:end -->

## Install

```bash
cd tracks/p3/drivers/elixir
mix local.hex --force
mix local.rebar --force
mix deps.get
```

Requires Elixir ~> 1.15 (per `mix.exs`).

## Quick Start

```elixir
{:ok, conn} = ScratchBird.Connection.connect(
  url: "scratchbird://user:pass@localhost:3092/mydb"
)
{:ok, result, conn} = ScratchBird.Connection.query(conn, "SELECT 1", [])
IO.inspect(result.rows)
ScratchBird.Connection.close(conn)
```

## Ecto Repo

```elixir
config :my_app, MyApp.Repo,
  adapter: ScratchBird.Ecto,
  url: "scratchbird://user:pass@localhost:3092/mydb"
```

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_MANAGER_DSN`
