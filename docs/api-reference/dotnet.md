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

## Diagnostics

- `ScratchBirdConnection.GetDiagnostics()` returns a `ConnectionDiagnosticsSummary` snapshot with:
  - connection state and health
  - sanitized endpoint/mode fields (`FrontDoorMode`, `Protocol`, `Host`, `Port`, `Database`)
  - optional pooled counters (`PoolDiagnosticsSummary`) when pooling is enabled and a pool exists
  - latest server diagnostics payloads (`QueryPlanSummary`, `SblrSummary`) when available
- `ScratchBirdConnection.GetPoolDiagnostics()` returns pooled counters for the current connection configuration.
- `ScratchBirdConnection.GetPoolDiagnostics(connectionString)` provides static access to pool counters without opening a connection.

## Telemetry

- `ScratchBirdConnection.GetTelemetrySummary()` returns aggregated per-operation metrics for this connection.
- `ScratchBirdConnection.ResetTelemetry()` clears recorded telemetry counters.
- `ConnectionTelemetrySummary` includes total invocation/success/failure counts plus `OperationTelemetrySummary` entries.
- Command paths report operation names such as `Command.ExecuteReader`, `Command.ExecuteNonQuery`, and `Command.ExecuteScalar`.

## Notifications

- `ScratchBirdConnection.AddNotificationListener(Action<ScratchBirdNotification>)` registers a callback for asynchronous server notifications.
- `ScratchBirdConnection.RemoveNotificationListener(Action<ScratchBirdNotification>)` removes a callback and returns whether removal occurred.
- `ScratchBirdConnection.GetNotification()` dequeues one pending notification (or `null` when none are queued).
- `ScratchBirdConnection.GetNotifications()` drains all pending notifications as an immutable snapshot list.
- `ScratchBirdConnection.ClearNotifications()` clears queued notifications without invoking callbacks.
- `ScratchBirdNotification` fields: `ProcessId`, `Channel`, `Payload`, `ChangeType`, `RowId`, `ReceivedUtc`.

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
