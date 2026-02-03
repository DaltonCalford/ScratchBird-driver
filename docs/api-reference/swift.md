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
- `onNotification(_ handler)`
- `lastQueryPlan()`, `lastSblrCompiled()`

## ScratchBirdConfig

- `init(dsn: String)`
- `init(host:port:database:user:password:sslmode:...)`

## Type Wrappers

- `Jsonb` (raw JSONB bytes)
- `Json`
- `Geometry`
- `Interval`
- `RawValue`
