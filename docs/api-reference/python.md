# Python Driver API Reference

## Module

- Package: `scratchbird`
- DB-API 2.0: `apilevel=2.0`, `threadsafety=2`, `paramstyle=named`

## Entry Points

- `scratchbird.connect(dsn=None, **kwargs)` -> `Connection`
- `Connection.cursor()` -> `Cursor`

## Connection

- `execute(sql, params=None)`
- `executemany(sql, seq_of_params)`
- `commit()`, `rollback()`, `close()`

## Cursor

- `execute(sql, params=None)`
- `executemany(sql, seq_of_params)`
- `fetchone()`, `fetchmany(size=None)`, `fetchall()`
- `description`, `rowcount`, `arraysize`

## SBWP v1.1 Extensions

Connection helpers available on `Connection`:

- `begin(...)` with transaction options
- `savepoint(name)`, `release_savepoint(name)`, `rollback_to_savepoint(name)`
- `get_session_schema()`, `set_session_schema(schema)`
- `set_option(name, value)`
- `ping()`
- `subscribe(channel, sub_type=0, filter_expr="")`, `unsubscribe(channel)`
- `execute_sblr(sblr_hash, sblr_bytecode=None, params=None)`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach()`, `attach_list()`
- `on_notification(handler)`
- `last_plan()`, `last_sblr()`
- `cancel()`
- `query_metadata(collection_name="tables", restrictions=None)`
- `get_schema(collection_name="tables", restrictions=None)`

## Parameters

Named parameters use `:name` placeholders. Positional sequences are also
accepted.

## Wrapper Types

Use these helper types for complex values:

- `scratchbird.Json`
- `scratchbird.Jsonb`
- `scratchbird.Geometry`
- `scratchbird.Range`
- `scratchbird.RawValue`

## Errors

Exceptions follow the DB-API hierarchy and map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
