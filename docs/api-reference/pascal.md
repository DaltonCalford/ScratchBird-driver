# Pascal/Delphi Driver API Reference

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
  - `GetCatalogs`, `GetSchemas`, `GetTables`, `GetColumns`, `GetIndexes`, `GetConstraints`
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
- `ExecuteSblr(SblrHash, Bytecode, Params)`
- `StreamControl(ControlType, WindowSize, TimeoutMs)`
- `AttachCreate(EmulationMode, DbName)`, `AttachDetach`, `AttachList`
- `OnNotification` event handler
- `GetLastPlan(out Plan)`, `GetLastSblr(out Compiled)`

## Wrapper Types

- `TScratchBirdJsonb` (`IScratchBirdJsonb`)
- `TScratchBirdGeometry` (`IScratchBirdGeometry`)
- `TScratchBirdRange` (`IScratchBirdRange`)
- `TScratchBirdInterval`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
