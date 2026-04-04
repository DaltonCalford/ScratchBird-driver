# Swift API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `partial`
- Best-in-class benchmark: `PostgresNIO`
- Authoritative lane spec: `docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/swift.md`
- Remaining gap summary: Cancellation timing, portal suspend/resume, richer metadata families, advanced type roundtrips, error propagation, and pool recovery semantics remain incomplete.
<!-- lane-status:end -->

## ScratchBirdConnection

- `connect(_ config: ScratchBirdConfig) async throws -> ScratchBirdConnection`
- `query(_ sql: String, _ params: [Any?] = []) async throws -> ScratchBirdResult`
- `executeBatch(_ sql: String, _ paramsBatch: [[Any?]]) async throws -> [ScratchBirdResult]`
- `queryMulti(_ statements: [String]) async throws -> [ScratchBirdResult]`
- `executeReturningFirstColumn(_ sql: String, _ params: [Any?] = []) async throws -> Any?`
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

## ScratchBirdConnectionPool

- `init(config:maxSize:)`
- `acquire()`, `release(_:)`
- `withConnection(_:)`
- `close()`

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
