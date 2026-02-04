# Elixir (Ecto) Driver

## Install

```bash
cd tracks/p3/drivers/elixir
mix deps.get
```

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
