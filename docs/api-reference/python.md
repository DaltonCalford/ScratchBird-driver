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
