# ScratchBird Elixir (Ecto) Driver

Native ScratchBird driver with an Ecto adapter. Uses SBWP v1.1 and binary-only
transfer.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Install (local dev)

```bash
cd elixir
mix local.hex --force
mix local.rebar --force
mix deps.get
```

Requires Elixir ~> 1.15 (per `mix.exs`).

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

Managed mode (`front_door_mode=manager_proxy`) is supported using the
`manager_*` connection parameters.

TLS is required. `sslmode` supports:
`disable` (rejected), `allow`, `prefer`, `require`, `verify-ca`, `verify-full`.

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
- `SCRATCHBIRD_TEST_MANAGER_DSN`

See `docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md` for requirements.
