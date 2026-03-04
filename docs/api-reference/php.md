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

## SBWP v1.1 Extensions

Advanced protocol operations are available on `ScratchBird\Connection`:

- `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
- `setOption(name, value)`
- `ping()`
- `subscribe(channel, subType = ..., filterExpr = "")`, `unsubscribe(channel)`
- `executeSblr(hash, bytecode = null, params = [])`
- `streamControl(controlType, windowSize, timeoutMs)`
- `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
- `onNotification(callable)`
- `lastPlan()`, `lastSblr()`
- `cancel()`
- `queryMetadata(collectionName = "tables")`
- `getSchema(collectionName = "tables", restrictions = [])`
- `getSchemaTree(expandParents = null, database = null, restrictions = [])`

## Wrapper Types

- `ScratchBird\PDO\Jsonb`
- `ScratchBird\PDO\Geometry`
- `ScratchBird\PDO\Range`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
