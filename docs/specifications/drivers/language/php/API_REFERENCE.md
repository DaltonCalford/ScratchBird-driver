# PHP Driver API Reference

Status: Draft
Priority: P0

## Core API Surface

- `new ScratchBirdPDO(dsn, username, password, options)`
- `close()`
- `prepare(sql, options = [])`
- `query(sql)`
- `exec(sql)`
- `beginTransaction()`
- `commit()`
- `rollBack()`
- `inTransaction()`
- `setAttribute(attr, value)` / `getAttribute(attr)`
- `errorInfo()` / `errorCode()`
- `lastInsertId(name = null)`
- `nativeSql(sql, params = [])`
- `nativeCallableSql(sql, params = [])`
- `call(sql, params = [])`
- `queryMulti(sql, params = [])`
- `executeMulti(sql, params = [])`
- `executeBatch(sql, batchParams)`
- `queryBatch(sql, batchParams)`
- `executeWithGeneratedKeys(sql, params = [])`
- `queryMetadata(collectionName = "tables")`
- `getSchema(collectionName = "tables", restrictions = [])`
- `getSchemaTree(expandParents = null, database = null, restrictions = [])`

## Connection Options

- `host`, `port`, `database`, `user`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`
- `connectTimeout`, `socketTimeout`, `application_name`
- `binaryTransfer` (must remain true)

## Result Handling

- Column metadata (name, type_oid, format).
- Row decoding per DRIVER_RESULT_DECODING.md.
- Multi-result traversal via `Statement::nextRowset()` / `nextset()`.
- Generated-key retrieval via `Statement::getGeneratedKeys()` and `executeWithGeneratedKeys(...)`.

## Errors

- Errors include SQLSTATE, message, detail, hint.
- Map to native exception types per DRIVER_ERROR_MAPPING.md.
