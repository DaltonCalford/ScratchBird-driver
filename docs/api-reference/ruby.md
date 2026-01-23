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

## Parameters

Supports positional arrays or named parameter hashes (`:name` or `@name` in SQL).

## Wrapper Types

- `Scratchbird::JSONB`
- `Scratchbird::Geometry`
- `Scratchbird::RangeValue`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
