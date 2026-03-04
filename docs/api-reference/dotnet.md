# .NET Driver API Reference

## Assembly

- Namespace: `ScratchBird.Data`
- Provider: `ScratchBirdConnection`, `ScratchBirdCommand`

## Core Types

- `ScratchBirdConnection` (DbConnection)
- `ScratchBirdCommand` (DbCommand)
- `ScratchBirdParameter` (DbParameter)
- `ScratchBirdDataReader` (DbDataReader)
- `ScratchBirdTransaction` (DbTransaction)
- `ScratchBirdConnectionStringBuilder`
- `ScratchBirdFactory`

## Wrapper Types

- `ScratchBirdJson`
- `ScratchBirdJsonb`
- `ScratchBirdGeometry`
- `ScratchBirdRange<T>`
- `ScratchBirdInterval`, `ScratchBirdDate`, `ScratchBirdTime`,
  `ScratchBirdTimestamp`, `ScratchBirdTimestampTz`, `ScratchBirdDecimal`,
  `ScratchBirdMoney`
- `ScratchBirdRaw`

## SBWP v1.1 Extensions

Advanced protocol operations are exposed on the internal `ProtocolClient`
owned by `ScratchBirdConnection`:

- `Begin()`, `Commit()`, `Rollback()`
- `Savepoint(name)`, `ReleaseSavepoint(name)`, `RollbackToSavepoint(name)`
- `SetOption(name, value)`
- `Ping()`
- `Subscribe(type, channel, filterExpr)`, `Unsubscribe(channel)`
- `ExecuteSblr(hash, bytecode, parameters, timeoutMs, maxRows)`
- `StreamControl(controlType, windowSize, timeoutMs)`
- `AttachCreate(emulationMode, dbName)`, `AttachDetach()`, `AttachList()`
- `OnNotification(handler)`
- `LastPlan`, `LastSblr`
- `Cancel()`

## Metadata

- `GetSchema(collectionName, restrictionValues)` supports extended metadata families (including unified `Routines`) and collection-scoped restriction filtering.
- Metadata restriction values support explicit `"null"` literal matching for nullable metadata columns.

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
