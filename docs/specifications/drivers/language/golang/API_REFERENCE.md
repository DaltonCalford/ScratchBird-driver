# Go Driver API Reference

Status: Draft
Priority: P0

## Core API Surface

- `sql.Open("scratchbird", dsn)` / `Driver.OpenConnector(dsn)`
- `Conn.PrepareContext(ctx, query)`
- `Conn.ExecContext(ctx, query, args)`
- `Conn.QueryContext(ctx, query, args)`
- `Conn.BeginTx(ctx, opts)` / `Tx.Commit()` / `Tx.Rollback()`
- `Conn.Savepoint(ctx, name)` / `Conn.ReleaseSavepoint(ctx, name)` / `Conn.RollbackToSavepoint(ctx, name)`
- `Tx.Savepoint(name)` / `Tx.ReleaseSavepoint(name)` / `Tx.RollbackToSavepoint(name)`
- `Conn.QueryMetadata(ctx, collection)`
- `Conn.QueryMetadataWithRestrictions(ctx, collection, restrictions)`
- `Rows.HasNextResultSet()` / `Rows.NextResultSet()`
- `Conn.NativeSQL(query, args)`
- `Conn.NativeCallableSQL(query, args)`
- `Conn.CallContext(ctx, query, args)`
- `Conn.QueryMultiContext(ctx, query, args)` / `Conn.ExecuteMultiContext(ctx, query, args)`
- `Conn.ExecuteBatchContext(ctx, query, batchArgs)` / `Conn.QueryBatchContext(ctx, query, batchArgs)`
- `Conn.ExecuteWithGeneratedKeysContext(ctx, query, args)`

## Connection Options

- `host`, `port`, `database`, `user`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`
- `connectTimeout`, `socketTimeout`, `application_name`
- `binaryTransfer` (must remain true)

## Result Handling

- Column metadata (name, type_oid, format).
- Row decoding per DRIVER_RESULT_DECODING.md.
- Multi-result traversal supported via `Rows.HasNextResultSet` and `Rows.NextResultSet`.
- Batch/multi execution summary types:
  - `BatchSummary`, `BatchItemSummary`, `ResultSetSummary`, `FieldSummary`.

## Errors

- Errors include SQLSTATE, message, detail, hint.
- Map to native exception types per DRIVER_ERROR_MAPPING.md.
