# Pascal/Delphi Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `FireDAC`
- Authoritative lane spec: `docs/specifications/drivers/language/pascal-delphi/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/pascal.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Units

- `ScratchBird.Client`
- `ScratchBird.Config`
- `ScratchBird.Types`
- Adapter units: `ScratchBird.FireDAC`, `ScratchBird.IBX`, `ScratchBird.Zeos`, `ScratchBird.SQLdb`

## TScratchBirdClient

- `Connect(dsn)` / `Disconnect()`
- `BeginTransaction()`, `Commit()`, `Rollback()`
- `ExecSQL(sql)` / `ExecSQLParams(sql, params)`
- `ExecuteQuery(sql)` / `ExecuteQueryParams(sql, params)` -> `TScratchBirdResultStream`
- `QueryMetadata(collectionName)` / `GetSchema(collectionName)` -> `TScratchBirdResultStream`
  - Supported collection families: `schemas`, `tables`, `columns`, `indexes`, `index_columns`, `constraints`, `procedures`, `functions`, `routines`, `catalogs`, `primary_keys`, `foreign_keys`, `table_privileges`, `column_privileges`, `type_info`.
  - Alias normalization is supported (for example `schema`, `indexColumns`, `pk`, `fk`, `typeinfo`).
- `QueryMetadataRows(collectionName, restrictions)` / `GetSchemaRows(collectionName, restrictions)` -> `TMetadataRows`
  - Materializes metadata rows and applies in-lane restriction filtering.
  - Restriction matching supports key aliases, `%`/`_` wildcards, and `null` literal matching for nullable columns.
- Typed metadata wrappers:
  - `GetCatalogs`, `GetSchemas`, `GetTables`, `GetColumns`, `GetIndexes`, `GetIndexColumns`, `GetConstraints`
  - `GetProcedures`, `GetFunctions`, `GetRoutines`
  - `GetPrimaryKeys`, `GetForeignKeys`
  - `GetTablePrivileges`, `GetColumnPrivileges`, `GetTypeInfo`

## TScratchBirdResultStream

- `ReadRow()` -> array of Variant
- `Columns`, `RowsAffected`, `CommandTag`

## SBWP v1.1 Extensions

`TScratchBirdClient` helpers:

- `BeginTransactionEx(...)`
- `Savepoint(Name)`, `ReleaseSavepoint(Name)`, `RollbackToSavepoint(Name)`
- `SetOption(Name, Value)`
- `Ping`, `Terminate`, `Cancel`
- `Subscribe(SubscribeType, Channel, FilterExpr)`, `Unsubscribe(Channel)`
- Notification lifecycle helpers:
  - `Listen(Channel, FilterExpr)`, `Unlisten(Channel)`, `UnlistenAll()`
  - `NotifyChannel(Channel)`, `NotifyChannel(Channel, Payload)`
  - `AddNotificationListener(Handler)`, `RemoveNotificationListener(ListenerId)`
  - `GetNotification(out Notice)`, `GetNotifications()`, `ClearNotifications()`, `NotificationCount()`
- `ExecuteSblr(SblrHash, Bytecode, Params)`
- `StreamControl(ControlType, WindowSize, TimeoutMs)`
- `AttachCreate(EmulationMode, DbName)`, `AttachDetach`, `AttachList`
- `OnNotification` event handler
- `GetLastPlan(out Plan)`, `GetLastSblr(out Compiled)`
- Enterprise diagnostics/observability helpers:
  - `GetDiagnosticsJson()`
  - `GetTelemetrySummaryJson()`, `ResetTelemetry()`
  - `GetSlowOperationsJson()`, `ExportTelemetryPrometheus()`
  - `GetCircuitBreakerSummaryJson()`, `GetKeepaliveSummaryJson()`, `GetLeakSummaryJson()`

## Wrapper Types

- `TScratchBirdJsonb` (`IScratchBirdJsonb`)
- `TScratchBirdGeometry` (`IScratchBirdGeometry`)
- `TScratchBirdRange` (`IScratchBirdRange`)
- `TScratchBirdInterval`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
