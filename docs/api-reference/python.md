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
- `is_valid(timeout_ms=0)`
- `subscribe(channel, sub_type=0, filter_expr="")`, `unsubscribe(channel)`
- `execute_sblr(sblr_hash, sblr_bytecode=None, params=None)`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach()`, `attach_list()`
- `on_notification(handler)`
- `last_plan()`, `last_sblr()`
- `cancel()`
- `query_metadata(collection_name="tables", restrictions=None)`
- `get_schema(collection_name="tables", restrictions=None)`
- `ddl_editor_schema_payload(schema_pattern=None, expand_schema_parents=None)`
- `schemas(catalog=None)`, `tables(schema=None, table=None, table_type=None)`
- `columns(schema=None, table=None, column=None, column_type=None)`, `indexes(schema=None, table=None, index=None)`
- `index_columns(schema=None, table=None, index=None, column=None)`, `constraints(schema=None, table=None, constraint=None)`
- `catalogs(catalog=None)`, `primary_keys(schema=None, table=None, constraint=None, catalog=None)`
- `foreign_keys(schema=None, table=None, constraint=None, catalog=None)`
- `procedures(schema=None, procedure=None, catalog=None)`, `functions(schema=None, function=None, catalog=None)`
- `routines(schema=None, routine=None, catalog=None)`
- `table_privileges(schema=None, table=None, catalog=None)`, `column_privileges(schema=None, table=None, column=None, catalog=None)`
- `type_info(type_name=None)`

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
