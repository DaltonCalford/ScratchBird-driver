# Swift API Reference

## ScratchBirdConnection

- `connect(_ config: ScratchBirdConfig) async throws -> ScratchBirdConnection`
- `query(_ sql: String, _ params: [Any?] = []) async throws -> ScratchBirdResult`
- `close() async throws`
- `begin(...)`, `commit(flags:)`, `rollback(flags:)`
- `savepoint(_ name)`, `releaseSavepoint(_ name)`, `rollbackToSavepoint(_ name)`
- `setOption(_ name, value:)`
- `ping()`, `cancel()`
- `subscribe(_ channel, subscribeType:filterExpr:)`, `unsubscribe(_ channel)`
- `executeSblr(_ hash, bytecode:, params:)`
- `streamControl(controlType:windowSize:timeoutMs:)`
- `attachCreate(emulationMode:dbName:)`, `attachDetach()`, `attachList()`
- `metadataSchemas()`, `metadataTables()`, `metadataColumns()`
- `metadataIndexes()`, `metadataIndexColumns()`, `metadataConstraints()`
- `metadataProcedures()`, `metadataFunctions()`
- `metadataSchemaTree(expandSchemaParents:)`, `metadataSchemaTreeRows(expandSchemaParents:)`
- `onNotification(_ handler)`
- `lastQueryPlan()`, `lastSblrCompiled()`

## ScratchBirdConfig

- `init(dsn: String)`
- `init(host:port:database:user:password:sslmode:...)`
- Resilience tuning fields:
  `keepaliveIntervalMs`, `keepaliveMaxIdleBeforeCheckMs`,
  `keepaliveValidationTimeoutMs`, `leakDetectionThresholdMs`,
  `leakDetectionCheckIntervalMs`, `leakDetectionCaptureStackTrace`

## Type Wrappers

- `Jsonb` (raw JSONB bytes)
- `Json`
- `Geometry`
- `Interval`
- `RawValue`

## Error Types

- Base: `ScratchBirdDriverException`
- Connection/auth: `ScratchBirdConnectionException`, `ScratchBirdAuthorizationException`
- Data/constraint: `ScratchBirdDataException`, `ScratchBirdIntegrityException`
- SQL execution: `ScratchBirdTransactionException`, `ScratchBirdProgrammingException`
- Capability/runtime: `ScratchBirdNotSupportedException`, `ScratchBirdTimeoutException`, `ScratchBirdOperationalException`
