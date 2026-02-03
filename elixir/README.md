# ScratchBird Elixir (Ecto) Driver

Native ScratchBird driver with an Ecto adapter. Uses SBWP v1.1 and binary-only
transfer.

## Install (local dev)

```bash
cd elixir
mix deps.get
```

## Quick Start

```elixir
config = [
  url: "scratchbird://user:pass@localhost:3092/mydb",
  application_name: "my_app"
]

{:ok, conn} = ScratchBird.Connection.connect(config)
{:ok, result, conn} = ScratchBird.Connection.query(conn, "SELECT 1", [])
IO.inspect(result.rows)
```

## Ecto Adapter

```elixir
# config/config.exs
config :my_app, MyApp.Repo,
  adapter: ScratchBird.Ecto,
  url: "scratchbird://user:pass@localhost:3092/mydb"
```

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`

See `docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md` for requirements.
