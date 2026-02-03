# Rust Driver API Reference

## Crate

- Crate name: `scratchbird`

## Entry Points

- `Config::from_dsn(dsn)`
- `Client::new(config)`
- `client.connect().await` / `client.close().await`

## Queries

- `client.query(sql).await` -> `QueryResult`
- `client.query_stream(sql).await` -> `QueryStream`
- `client.prepare(name, sql).await`
- `client.execute(name, params).await`

## SBWP v1.1 Extensions

Advanced protocol operations on `Client`:

- `begin(options)` / `commit(options)` / `rollback(options)`
- `savepoint(name)`, `release_savepoint(name)`, `rollback_to_savepoint(name)`
- `set_option(name, value)`
- `ping()`, `terminate()`, `cancel()`
- `subscribe(subscribe_type, channel, filter_expr)`, `unsubscribe(channel)`
- `execute_sblr(hash, bytecode, params)`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach()`, `attach_list()`
- `on_notification(handler)`
- `last_query_plan()`, `last_sblr_compiled()`

## Parameters

Use `types::Param` for explicit type binding or pass supported native values.

## Wrapper Types

- `Json`, `Jsonb`
- `Geometry`
- `Range<T>`, `RangeValue`
- `Interval`, `Date`, `Time`, `Timestamp`, `TimestampTz`
- `Decimal`, `Money`
- `RawValue`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
