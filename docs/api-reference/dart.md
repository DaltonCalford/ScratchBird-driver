# Dart API Reference

## ScratchBirdClient

- `ScratchBirdClient.connect(ScratchBirdConfig config)`
- `query(String sql, [List<dynamic> params])`
- `close()`
- `begin(...)`, `commit([flags])`, `rollback([flags])`
- `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
- `setOption(name, value)`
- `ping()`, `terminate()`, `cancel()`
- `subscribe(channel, {subscribeType, filterExpr})`, `unsubscribe(channel)`
- `executeSblr(hash, bytecode, [params])`
- `streamControl(controlType, windowSize, timeoutMs)`
- `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
- `onNotification(handler)`
- `lastQueryPlan`, `lastSblrCompiled`

## ScratchBirdConfig

- `ScratchBirdConfig.fromDsn(String dsn)`

## Type Wrappers

- `ScratchBirdJsonb`
- `ScratchBirdJson`
- `ScratchBirdGeometry`
- `ScratchBirdRange`
- `ScratchBirdInterval`
- `RawValue`
