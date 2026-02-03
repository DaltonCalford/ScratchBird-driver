# Mojo API Reference

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
