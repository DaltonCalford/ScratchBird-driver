# Python Driver API Reference

Status: Draft
Priority: P0

## Core API Surface

- `connect(options)`
- `close()`
- `query(sql, params)`
- `execute(sql, params)`
- `query_multi(sql, params)`
- `execute_multi(sql, params)`
- `execute_batch(sql, batch_params)`
- `query_batch(sql, batch_params)`
- `execute_with_generated_keys(sql, params)`
- `query_metadata(collection_name='tables', restrictions=None)`
- `get_schema(collection_name='tables', restrictions=None)`
- `prepare(sql)`
- `begin()`
- `commit()`
- `rollback()`
- `get_session_schema()`
- `set_session_schema(schema)`
- `schemas()`
- `tables(schema)`
- `columns(schema, table)`
- `indexes(schema, table)`

## Connection Options

- `host`, `port`, `database`, `user`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`
- `connectTimeout`, `socketTimeout`, `application_name`
- `binaryTransfer` (must remain true)

## Result Handling

- Column metadata (name, type_oid, format).
- Row decoding per DRIVER_RESULT_DECODING.md.
- Generated keys via cursor result-set API (`get_generated_keys()`).

## Errors

- Errors include SQLSTATE, message, detail, hint.
- Map to native exception types per DRIVER_ERROR_MAPPING.md.
