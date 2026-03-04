# Node.js/TypeScript Driver API Reference

Status: Draft (updated for TXN/EXEC parity surfaces)  
Priority: P0

## Package

- NPM package: `scratchbird`
- Main exports: `Client`, `Pool`

## Client API

### Lifecycle and connection

- `new Client(configOrDsn)`
- `connect()`
- `end()`
- `terminate()`

### Core execution

- `query(sql, params?, options?)`
- `queryStream(sql, params?, options?)`
- `prepare(name, sql)`
- `execute(name, params?, options?)` (prepared statement execution)

### EXEC parity surfaces

- `nativeSQL(sql, params?)`
- `nativeCallableSQL(sql, params?)`
- `call(sql, params?, options?)`
- `queryMulti(sql, params?, options?)`
- `executeMulti(name, params?, options?)`
- `queryBatch(sql, batchParams, options?)`
- `executeBatch(name, batchParams, options?)`
- `executeWithGeneratedKeys(sql, params?, options?)`

### Transaction and session

- `begin()` / `beginTransaction(options?)`
- `commit()` / `commitTransaction(options?)`
- `rollback()` / `rollbackTransaction(options?)`
- `savepoint(name)`
- `releaseSavepoint(name)`
- `rollbackToSavepoint(name)`
- `getAutoCommit()`
- `setAutoCommit(enabled)`
- `getSessionSchema()`
- `setSessionSchema(schema)`

### Metadata

- `queryMetadata(collectionName = "tables", restrictions?)`
- `getSchema(collectionName = "tables", restrictions?)`
- `getSchemaTree(options?)`

### Advanced SBWP operations

- `setOption(name, value)`
- `ping()`
- `subscribe(channel, options?)`
- `unsubscribe(channel)`
- `executeSblr(hash, bytecode?, params?, options?)`
- `streamControl(controlType, windowSize, timeoutMs)`
- `attachCreate(emulationMode, dbName)`
- `attachDetach()`
- `attachList()`
- `onNotification(handler)`
- `getLastPlan()`
- `getLastSblr()`

## Pool API

- `new Pool(configOrDsn)`
- `connect()`
- `query(sql, params?, options?)`
- `end()`

## Query Options

- `signal` (`AbortSignal`)
- `maxRows`
- `timeoutMs`
- `includePlan`
- `returnSblr`
- `describeOnly`
- `noCache`

## Connection Options

- `host`, `port`, `database`, `user`, `password`
- `frontDoorMode` (`direct` / `manager_proxy`)
- `protocol` (`native` only)
- `schema`, `role`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`, `sslpassword`
- `connectTimeoutMs`, `socketTimeoutMs`
- `applicationName`
- `binaryTransfer` (must remain `true`)
- `compression` (`zstd` rejected)
- `metadataExpandSchemaParents`
- manager-proxy options:
  - `managerAuthToken`
  - `managerUsername`
  - `managerDatabase`
  - `managerConnectionProfile`
  - `managerClientIntent`
  - `managerClientFlags`
  - `managerAuthFastPath`

## Result Types

- `QueryResult<T>`
  - `rows`, `rowCount`, `fields`, `command`, `lastId`
- `BatchResult`
  - `items`, `totalRowCount`
- `BatchItemResult`
  - `index`, `rowCount`, `fields`, `command`, `lastId`

## Errors

- Base class: `ScratchbirdError`
- Structured fields: `code` (SQLSTATE), `detail`, `hint`
- SQLSTATE mappings are surfaced through typed subclasses:
  - `ScratchbirdWarning`
  - `ScratchbirdNoDataError`
  - `ScratchbirdConnectionError`
  - `ScratchbirdNotSupportedError`
  - `ScratchbirdDataError`
  - `ScratchbirdIntegrityError`
  - `ScratchbirdAuthError`
  - `ScratchbirdTransactionError`
  - `ScratchbirdSyntaxError`
  - `ScratchbirdResourceError`
  - `ScratchbirdLimitError`
  - `ScratchbirdOperatorInterventionError`
  - `ScratchbirdSystemError`
  - `ScratchbirdInternalError`
