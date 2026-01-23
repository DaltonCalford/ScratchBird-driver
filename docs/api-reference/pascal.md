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

## Wrapper Types

- `TScratchBirdJsonb` (`IScratchBirdJsonb`)
- `TScratchBirdGeometry` (`IScratchBirdGeometry`)
- `TScratchBirdRange` (`IScratchBirdRange`)
- `TScratchBirdInterval`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
