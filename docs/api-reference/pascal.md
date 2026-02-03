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
