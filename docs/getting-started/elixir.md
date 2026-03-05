# Elixir (Ecto) Driver

## Status

SBWP v1.1 core implementation with TLS-required/binary-only guards, SQLSTATE class mapping, metadata helper queries, and env-gated integration coverage.

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
