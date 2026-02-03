# Ruby Driver API Reference

## Module

- Namespace: `Scratchbird`
- Entry point: `Scratchbird.connect(dsn_or_options)`

## Connection

- `query(sql, params = nil)` / `execute(sql, params = nil)`
- `stream(sql, params = nil)`
- `prepare(sql)` -> `Statement`
- `begin_transaction`, `commit`, `rollback`
- `autocommit` (boolean)
- `close`, `closed?`

## Statement

- `execute(params = nil)`
- `close`

## SBWP v1.1 Extensions

Advanced protocol operations are exposed on `Scratchbird::Client` (via
`Connection#client`):

- `savepoint(name)`, `release_savepoint(name)`, `rollback_to_savepoint(name)`
- `set_option(name, value)`
- `ping`
- `subscribe(channel, sub_type = ..., filter_expr = "")`, `unsubscribe(channel)`
- `execute_sblr(hash, bytecode = nil, params = [])`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach`, `attach_list`
- `on_notification { |notice| ... }`
- `last_plan`, `last_sblr`

## Parameters

Supports positional arrays or named parameter hashes (`:name` or `@name` in SQL).

## Wrapper Types

- `Scratchbird::JSONB`
- `Scratchbird::Geometry`
- `Scratchbird::RangeValue`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
