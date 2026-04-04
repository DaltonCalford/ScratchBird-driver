# Elixir (Ecto) API Reference

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

## ScratchBird.Connection

- `connect(opts)` -> `{:ok, conn} | {:error, reason}`
- `query(conn, sql, params)` -> `{:ok, result, conn} | {:error, reason, conn}`
- `close(conn)`
- `begin(conn, opts)`, `commit(conn, flags)`, `rollback(conn, flags)`
- `savepoint(conn, name)`, `release_savepoint(conn, name)`, `rollback_to_savepoint(conn, name)`
- `set_option(conn, name, value)`
- `ping(conn)`, `cancel(conn)`
- `subscribe(conn, channel, opts)`, `unsubscribe(conn, channel)`
- `execute_sblr(conn, hash, bytecode, params)`
- `stream_control(conn, control_type, window_size, timeout_ms)`
- `attach_create(conn, emulation_mode, db_name)`, `attach_detach(conn)`, `attach_list(conn)`
- `on_notification(conn, handler)`
- `last_query_plan(conn)`, `last_sblr_compiled(conn)`

## ScratchBird.Ecto

- Ecto adapter for `Ecto.Repo`
- Uses `ScratchBird.Ecto.Connection` for DBConnection integration

## Type Wrappers

- `ScratchBird.Types.Jsonb`
- `ScratchBird.Types.Range`
- `ScratchBird.Types.Geometry`
