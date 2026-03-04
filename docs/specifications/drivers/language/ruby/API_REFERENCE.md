# Ruby Driver API Reference

Status: Draft (updated for TXN/EXEC parity surfaces)  
Priority: P1

## Entry Points

- `Scratchbird.connect(dsn_or_options)` -> `Scratchbird::Connection`
- `Scratchbird::Config.parse(dsn)` for DSN parsing and normalization

## Connection API (`Scratchbird::Connection`)

### Lifecycle and transaction control

- `close()` / `closed?()`
- `autocommit` (boolean accessor)
- `begin_transaction()`
- `commit()`
- `rollback()`
- `in_transaction?()`
- `savepoint(name)`
- `rollback_to_savepoint(name)`
- `release_savepoint(name)`

### Core execution

- `query(sql, params = nil, options = nil)`
- `execute(sql, params = nil, options = nil)` (alias-style behavior of `query`)
- `stream(sql, params = nil, options = nil)`
- `prepare(sql)` -> `Scratchbird::Statement`
- `execute_prepared(name, params = nil, options = nil)`
- `stream_prepared(name, params = nil, options = nil)`
- `close_prepared(name)`

### EXEC parity surfaces

- `native_sql(sql, params = nil)`
- `native_callable_sql(sql, params = nil)`
- `call(sql, params = nil, options = nil)`
- `query_multi(sql, params = nil, options = nil)`
- `execute_multi(sql, params = nil, options = nil)`
- `execute_batch(sql, batch_params, options = nil)`
- `query_batch(sql, batch_params, options = nil)`
- `execute_with_generated_keys(sql, params = nil, options = nil)`

### Metadata surfaces

- `query_metadata(collection_name = "tables", options = nil)`
- `query_metadata_with_restrictions(collection_name = "tables", restrictions = nil, options = nil)`
- `get_schema(collection_name = "tables", options = nil, expand_schema_parents: nil)`
- `get_schema_with_restrictions(collection_name = "tables", restrictions = nil, options = nil, expand_schema_parents: nil)`
- `get_schema_tree(expand_schema_parents: nil, database: nil, default_branch: "default", restrictions: nil)`

## Statement API (`Scratchbird::Statement`)

- `execute(params = nil, options = nil)`
- `stream(params = nil, options = nil)`
- `close()`
- `closed?()`

## Execution Options

Execution methods accept an `options` hash with the following keys:

- `:max_rows`
- `:timeout_ms`
- `:include_plan`
- `:return_sblr`
- `:describe_only`
- `:no_cache`

## Parameter Handling

- Positional placeholders: `?` are rewritten to wire placeholders (`$1`, `$2`, ...)
- Named placeholders: `:name` and `@name` are supported
- Callable escape normalization:
  - `{ call routine(...) }`
  - `{ ? = call routine(...) }`
- Binary parameter mode is required (`binary_transfer=true`); non-binary mode is rejected.

## Result Types

- `Scratchbird::Result`
  - `columns`, `rows`, `rowcount`, `command_tag`, `last_insert_id`
  - `fields()`, `first()`, `each()`, `each_hash()`
- `Scratchbird::ResultStream`
  - `columns`, `rowcount`, `command_tag`, `last_insert_id`
  - `each()`, `each_hash()`, `to_a()`
  - single-consumption iterator semantics
- Batch/multi summary structs
  - `Scratchbird::FieldSummary`
  - `Scratchbird::ResultSetSummary`
  - `Scratchbird::BatchItemSummary`
  - `Scratchbird::BatchSummary`

## Metadata Collections

Supported collection names (including aliases):

- `schemas`
- `tables`
- `columns`
- `indexes`
- `index_columns`
- `constraints`
- `procedures`
- `functions`

## Connection Options

Primary config fields:

- `host`, `port`, `database`, `user`, `password`
- `schema`, `role`
- `protocol` (`native` only)
- `front_door_mode` (`direct` or `manager_proxy`)
- `sslmode`, `sslrootcert`, `sslcert`, `sslkey`, `sslpassword`
- `connect_timeout_ms`, `socket_timeout_ms`
- `application_name`
- `binary_transfer` (must remain `true`)
- `compression` (`zstd` rejected)
- `metadata_expand_schema_parents`
- Manager-proxy options:
  - `manager_auth_token`
  - `manager_username`
  - `manager_database`
  - `manager_connection_profile`
  - `manager_client_intent`
  - `manager_client_flags`
  - `manager_auth_fast_path`

## Error Model

- Base class: `Scratchbird::Error`
- Structured fields: `sqlstate`, `detail`, `hint`
- SQLSTATE family mapping is provided via `Scratchbird::ErrorMapper.from_sqlstate(...)`
- Specialized subclasses include:
  - `ConnectionError`
  - `NotSupportedError`
  - `DataError`
  - `IntegrityError`
  - `AuthError`
  - `TransactionError`
  - `SyntaxError`
  - `ResourceError`
  - `LimitError`
  - `OperatorInterventionError`
  - `SystemError`
  - `InternalError`
