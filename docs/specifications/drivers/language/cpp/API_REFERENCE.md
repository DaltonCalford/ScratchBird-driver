# C/C++ Driver API Reference

Status: Draft
Priority: P2

## Core API Surface

- `connect(options)`
- `close()`
- `query(sql, params)`
- `execute(sql, params)`
- `prepare(sql)`
- `begin()`
- `commit()`
- `rollback()`
- `metadataQuery(collection)`
- `schemas()`
- `tables(schema)`
- `columns(schema, table)`
- `indexes(schema, table)`
- `metadataSchemaPayload(schema_pattern, expand_parents)`

## Connection Options

- `host`, `port`, `database`, `user`, `password`
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`
- `connectTimeout`, `socketTimeout`, `application_name`
- `binaryTransfer` (must remain true)

## Result Handling

- Column metadata (`name`, mapped `sb_type`, `type_oid`, `format`, `nullable`).
- Row decoding per DRIVER_RESULT_DECODING.md.

## Errors

- Errors include SQLSTATE, message, detail, hint.
- Map to native exception types per DRIVER_ERROR_MAPPING.md.
