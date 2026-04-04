# Mojo API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `hybrid_native_gap`
- Best-in-class benchmark: `Composite (asyncpg + pgx + PostgresNIO)`
- Authoritative lane spec: `docs/specifications/DRIVER_MOJO_NATIVE_API.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/mojo.md`
- Remaining gap summary: The lane is functionally strong but still depends on the Python bridge; native Mojo transport/auth remains the primary architectural gap.
<!-- lane-status:end -->

## ScratchBirdConfig

- `ScratchBirdConfig(dsn = "")`
- `to_dsn()`

## ScratchBirdConnection

- `connect()`, `close()`, `terminate()`
- `query(sql, params)`
- `stream(sql, params)`
- `prepare(sql)` -> `ScratchBirdStatement`
- `transaction(fn)`
- `begin(...)`, `commit(flags)`, `rollback(flags)`
- `savepoint(name)`, `release_savepoint(name)`, `rollback_to_savepoint(name)`
- `set_option(name, value)`
- `ping()`, `cancel()`
- `subscribe(channel, sub_type, filter_expr)`, `unsubscribe(channel)`
- `execute_sblr(hash, bytecode, params)`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach()`, `attach_list()`
- `on_notification(handler)`
- `last_query_plan()`, `last_sblr_compiled()`

## ScratchBirdStatement

- `execute(params)`

## Notes

The Mojo adapter uses the ScratchBird Python driver as a transport bridge
until Mojo-native sockets/TLS are available.
