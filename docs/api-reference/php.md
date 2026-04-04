# PHP Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `PDO_PGSQL`
- Authoritative lane spec: `docs/specifications/drivers/language/php/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/php.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Namespaces

- PDO-style surface: `ScratchBird\PDO`
- Low-level/supporting classes: `ScratchBird`

## `ScratchBird\PDO\ScratchBirdPDO`

- `__construct(dsn, username = null, password = null, options = [])`
- `prepare(sql)` -> `Statement`
- `query(sql)` -> `Statement`
- `exec(sql)` -> affected row count
- `beginTransaction()`, `commit()`, `rollBack()`
- `lastInsertId(name = null)`
- `setAttribute()`, `getAttribute()`
- `errorInfo()`, `errorCode()`
- `close()`

## `ScratchBird\PDO\Statement`

- `bindParam(...)`, `bindValue(...)`
- `execute(params = null)`
- `fetch()`, `fetchAll()`, `fetchColumn()`
- `rowCount()`, `columnCount()`, `getColumnMeta()`
- `closeCursor()`, `setFetchMode(...)`
- `nextRowset()` / `nextset()`
- `statusMessage()`, `lastInsertId()`, `getGeneratedKeys()`, `fields()`

## `ScratchBird\Connection`

Extended execution and protocol helpers:

- `nativeSql(sql, params = [])`, `nativeCallableSql(sql, params = [])`
- `call(sql, params = [])`
- `executeBatch(sql, batchParams)`, `queryBatch(sql, batchParams)`
- `queryMulti(sql, params = [])`, `executeMulti(sql, params = [])`
- `executeWithGeneratedKeys(sql, params = [])`
- `queryMetadata(collectionName = "tables")`
- `getSchema(collectionName = "tables", restrictions = [])`
- `getSchemaTree(expandParents = null, database = null, restrictions = [])`
- `beginTransaction()`, `inTransaction()`, `commit()`, `rollBack()`
- `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
- `setOption(name, value)`, `ping()`, `cancel()`
- `subscribe(channel, subType = ..., filterExpr = "")`, `unsubscribe(channel)`
- `executeSblr(hash, bytecode = null, params = [])`
- `streamControl(controlType, windowSize, timeoutMs)`
- `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
- `onNotification(callable)`
- `lastPlan()`, `lastSblr()`

## Supporting Classes

- `ScratchBird\Config`
- `ScratchBird\TelemetryCollector`, `ScratchBird\TelemetryConfig`
- `ScratchBird\CircuitBreaker`, `ScratchBird\CircuitBreakerConfig`
- `ScratchBird\KeepaliveManager`, `ScratchBird\KeepaliveConfig`
- `ScratchBird\LeakDetector`, `ScratchBird\LeakDetectionConfig`
- `ScratchBird\Metadata`

## Wrapper Types

- `ScratchBird\PDO\Jsonb`
- `ScratchBird\PDO\Geometry`
- `ScratchBird\PDO\Range`
- `ScratchBird\PDO\Composite`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
