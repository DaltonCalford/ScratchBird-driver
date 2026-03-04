# .NET/C# Driver API Reference

Status: Active (alpha lane)
Priority: P0

## Core API Surface

- `ScratchBirdConnection.Open()/Close()`
- `ScratchBirdCommand.ExecuteReader/ExecuteScalar/ExecuteNonQuery`
- `ScratchBirdCommand.Prepare()`
- `BeginTransaction()/Commit()/Rollback()`
- `GetSchema(...)`

## EXEC Parity Surfaces

- `NativeSql(sql, params?)`
- `NativeCallableSql(sql, params?)`
- `Call(sql, params?, commandTimeoutSeconds?, fetchSize?)`
- `QueryMulti(sql, params?, commandTimeoutSeconds?, fetchSize?)`
- `ExecuteMulti(sql, params?, commandTimeoutSeconds?, fetchSize?)`
- `ExecuteBatch(sql, batchParams, commandTimeoutSeconds?, fetchSize?)`
- `QueryBatch(sql, batchParams, commandTimeoutSeconds?, fetchSize?)`
- `ExecuteWithGeneratedKeys(sql, params?, commandTimeoutSeconds?, fetchSize?)`

## Transaction Surface

- `BeginTransaction(IsolationLevel)`
- Savepoint lifecycle through `ScratchBirdTransaction`:
  - `Save(name)`
  - `Rollback(name)`
  - `Release(name)`

## Metadata Surface

- `GetSchema(collectionName, restrictionValues)`
- recursive schema-parent expansion via connection config:
  - `metadata_expand_schema_parents=true`

Restriction filtering is collection-scoped across extended metadata families (`Catalogs`, `Indexes`, `IndexColumns`, key/privilege collections, `Procedures`, `Functions`, `Routines`, `TypeInfo`) and supports explicit `"null"` literal matching for nullable metadata fields.

## Key Result Models

- `ResultSetSummary`
  - `Rows`
  - `RowCount`
  - `Fields`
  - `Command`
  - `LastInsertId`
- `BatchItemSummary`
  - `Index`
  - `RowCount`
  - `Fields`
  - `Command`
  - `LastInsertId`
- `BatchSummary`
  - `Items`
  - `TotalRowCount`

## Connection String Options

- `host`, `port`, `database`, `user`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`
- `connectTimeout`, `socketTimeout`, `application_name`
- `binaryTransfer` (must remain true)

## Errors

- Errors include SQLSTATE, message, detail, hint.
- SQLSTATE maps to typed exceptions:
  - `ScratchBirdConnectionException`
  - `ScratchBirdNotSupportedException`
  - `ScratchBirdDataException`
  - `ScratchBirdTransactionException`
  - `ScratchBirdSyntaxException`
