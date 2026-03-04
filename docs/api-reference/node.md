# Node.js Driver API Reference

## Package

- NPM package: `scratchbird`
- Main exports: `Client`, `Pool`

## Client

- `new Client(config | dsn)`
- `connect()`
- `query(sql, params?, options?)`
- `queryMulti(sql, params?, options?)`
- `queryBatch(sql, batchParams, options?)`
- `queryStream(sql, params?, options?)` -> async generator
- `prepare(name, sql)`
- `execute(name, params?, options?)`
- `executeMulti(name, params?, options?)`
- `executeBatch(name, batchParams, options?)`
- `executeWithGeneratedKeys(sql, params?, options?)`
- `nativeSQL(sql, params?)`, `nativeCallableSQL(sql, params?)`
- `call(sql, params?, options?)`
- `begin()`, `commit()`, `rollback()`
- `getAutoCommit()`, `setAutoCommit(enabled)`
- `getSessionSchema()`, `setSessionSchema(schema)`
- `queryMetadata(collectionName?, restrictions?)`
- `getSchema(collectionName?, restrictions?)`, `getSchemaTree(options?)`
- `end()`
- `terminate()`
- `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
- `setOption(name, value)`
- `ping()`
- `subscribe(channel, options?)`, `unsubscribe(channel)`
- `executeSblr(hash, bytecode?, params?, options?)`
- `streamControl(controlType, windowSize?, timeoutMs?)`
- `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
- `onNotification(handler)`
- `getLastPlan()`, `getLastSblr()`

### Query Options

- `signal` (AbortSignal)
- `maxRows`
- `timeoutMs`
- `includePlan`
- `returnSblr`
- `describeOnly`
- `noCache`

## Pool

- `new Pool(config | dsn)`
- `connect()`
- `query(sql, params?, options?)`
- `end()`

## Parameters

Supports positional arrays or named parameter objects (`:name` or `@name` in SQL).

## Wrapper Types

- `ScratchbirdJson`
- `ScratchbirdJsonb`
- `ScratchbirdGeometry`
- `ScratchbirdRange<T>`
- `ScratchbirdRaw`
- `ScratchbirdInterval`, `ScratchbirdDate`, `ScratchbirdTime`,
  `ScratchbirdTimestamp`, `ScratchbirdTimestampTZ`, `ScratchbirdDecimal`,
  `ScratchbirdMoney`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
