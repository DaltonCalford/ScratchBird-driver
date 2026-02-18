# Elixir (Ecto) Driver

## Status

Partial SBWP v1.1 implementation. TLS required, binary-only enforced, zstd rejected; metadata helpers and conformance coverage remain incomplete.

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
{:ok, result} = ScratchBird.Connection.query(conn, "SELECT 1", [])
IO.inspect(result.rows)
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
