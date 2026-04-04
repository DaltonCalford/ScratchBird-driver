# Dart API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `partial`
- Best-in-class benchmark: `postgres (Dart)`
- Authoritative lane spec: `docs/specifications/DRIVER_DART_DATABASE_API.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/dart.md`
- Remaining gap summary: Live TXN failure-path validation, pagination/portal-suspend coverage, richer metadata families, complex-type roundtrips, and resilience cleanup proof remain open.
<!-- lane-status:end -->

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
