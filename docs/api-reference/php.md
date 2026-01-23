# PHP Driver API Reference

## Namespace

- Namespace: `ScratchBird\PDO`
- Entry point: `ScratchBirdPDO`

## ScratchBirdPDO

- `__construct(dsn, username = null, password = null, options = [])`
- `prepare(sql)` -> `Statement`
- `query(sql)` -> `Statement`
- `exec(sql)` -> affected row count
- `beginTransaction()`, `commit()`, `rollBack()`
- `lastInsertId(name = null)`
- `setAttribute()`, `getAttribute()`
- `errorInfo()`, `errorCode()`
- `close()`

## Statement

- `execute(params = null)`
- `fetch()`, `fetchAll()`, `rowCount()`

## Wrapper Types

- `ScratchBird\PDO\Jsonb`
- `ScratchBird\PDO\Geometry`
- `ScratchBird\PDO\Range`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
