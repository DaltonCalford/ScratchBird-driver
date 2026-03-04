# Pascal/Delphi Driver API Reference

Status: Active (alpha lane)
Priority: P0

## Core API Surface (`TScratchBirdClient`)

- `Connect(dsn)` / `Disconnect()`
- `BeginTransaction()`, `Commit()`, `Rollback()`
- `BeginTransactionEx(...)`
- `Savepoint(Name)`, `ReleaseSavepoint(Name)`, `RollbackToSavepoint(Name)`
- `ExecSQL(sql)` / `ExecSQLParams(sql, params)`
- `ExecuteQuery(sql)` / `ExecuteQueryParams(sql, params)` -> `TScratchBirdResultStream`
- `QueryMetadata(collectionName)` / `GetSchema(collectionName)` -> `TScratchBirdResultStream`
- `QueryMetadataRows(collectionName, restrictions)` / `GetSchemaRows(collectionName, restrictions)` -> `TMetadataRows`
- Typed metadata wrappers:
  - `GetCatalogs`, `GetSchemas`, `GetTables`, `GetColumns`, `GetIndexes`, `GetConstraints`
  - `GetProcedures`, `GetFunctions`, `GetRoutines`
  - `GetPrimaryKeys`, `GetForeignKeys`
  - `GetTablePrivileges`, `GetColumnPrivileges`, `GetTypeInfo`

## Metadata Collections

`QueryMetadata` / `GetSchema` support normalized metadata families:

- `schemas`, `tables`, `columns`, `indexes`, `index_columns`, `constraints`
- `procedures`, `functions`, `routines`
- `catalogs`, `primary_keys`, `foreign_keys`
- `table_privileges`, `column_privileges`, `type_info`

Alias forms are accepted (for example `schema`, `indexColumns`, `pk`, `fk`, `typeinfo`).

`QueryMetadataRows` / `GetSchemaRows` apply in-lane restriction filtering with:
- key alias mapping,
- `%` / `_` wildcard matching,
- `null` literal handling for nullable-column restrictions.

## Connection Options

- `host`, `port`, `database`, `user`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`
- `connectTimeout`, `socketTimeout`, `application_name`
- `binaryTransfer` (must remain true)

## Result Handling

- `TScratchBirdResultStream.ReadRow()` returns `array of Variant`
- Stream exposes `Columns`, `RowsAffected`, `CommandTag`
- Row decoding follows `DRIVER_RESULT_DECODING.md`

## Errors

- Exceptions carry SQLSTATE/message/detail/hint
- SQLSTATE category mapping is defined in `DRIVER_ERROR_MAPPING.md`
