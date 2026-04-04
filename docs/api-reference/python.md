# Python Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `psycopg3`
- Authoritative lane spec: `docs/specifications/drivers/language/python/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/python.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Module

- Package: `scratchbird`
- DB-API 2.0: `apilevel=2.0`, `threadsafety=2`, `paramstyle=named`

## Entry Points

- `scratchbird.connect(dsn=None, **kwargs)` -> `Connection`
- `Connection.cursor()` -> `Cursor`
- Pool helpers exported from `scratchbird`:
  `ConnectionPool`, `PoolConfig`, `StatementCache`, `CachingConnection`,
  `retry_with_backoff`

## `Connection`

DB-API and convenience execution:

- `execute(sql, params=None)`
- `executemany(sql, seq_of_params)`
- `query_multi(sql, params=None)`, `execute_multi(sql, params=None)`
- `execute_batch(sql, batch_params)`, `query_batch(sql, batch_params)`
- `execute_with_generated_keys(sql, params=None)`
- `native_sql(sql, params=None)`, `native_callable_sql(sql, params=None)`
- `call(sql, params=None)`
- `commit()`, `rollback()`, `close()`

Transactions, session, notifications, and protocol extensions:

- `begin(...)`
- `savepoint(name)`, `release_savepoint(name)`, `rollback_to_savepoint(name)`
- `get_session_schema()`, `set_session_schema(schema)`
- `set_option(name, value)`
- `ping()`, `is_valid(timeout_ms=0)`, `cancel()`
- `subscribe(channel, sub_type=0, filter_expr="")`, `unsubscribe(channel)`
- `execute_sblr(sblr_hash, sblr_bytecode=None, params=None)`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach()`, `attach_list()`
- `on_notification(handler)`
- `last_plan()`, `last_sblr()`
- `copy_in(sql, data, format=...)`, `copy_out(sql, format=...)`

Metadata:

- `query_metadata(collection_name="tables", restrictions=None)`
- `get_schema(collection_name="tables", restrictions=None)`
- `ddl_editor_schema_payload(schema_pattern=None, expand_schema_parents=None)`
- wrapper helpers:
  `schemas`, `tables`, `columns`, `indexes`, `index_columns`,
  `constraints`, `catalogs`, `primary_keys`, `foreign_keys`,
  `procedures`, `functions`, `routines`, `table_privileges`,
  `column_privileges`, `type_info`

## `Cursor`

- `execute(sql, params=None)`
- `executemany(sql, seq_of_params)`
- `fetchone()`, `fetchmany(size=None)`, `fetchall()`
- `has_next_result_set()`, `next_result_set()`
- `description`, `rowcount`, `arraysize`, `statusmessage`, `lastrowid`

Cursor state rule:

- Calling `execute()` again on the same cursor now discards any unread rows or
  unread result-set trailers from the prior statement before sending the new
  query. If the caller needs remaining rows or additional result sets, it must
  consume them with `fetch*()` or `nextset()` before re-executing.

## Pipeline Module

Import from `scratchbird.pipeline`:

- `PipelineConfig`
- `QueryPipeline`
- `AsyncQueryPipeline`
- `PipelineBuilder`

## Metadata Helpers

Import from `scratchbird`:

- `normalize_collection_name`, `normalize_restrictions`
- `resolve_collection_query`, `filter_rows_by_restrictions`
- `schema_paths_for_navigation`, `expand_schema_parent_paths`
- `build_schema_tree`, `build_ddl_editor_schema_payload`

## Wrapper Types

Use these helper types for complex values:

- `scratchbird.Json`
- `scratchbird.Jsonb`
- `scratchbird.Blob`
- `scratchbird.Clob`
- `scratchbird.RowId`
- `scratchbird.Ref`
- `scratchbird.SqlXml`
- `scratchbird.Geometry`
- `scratchbird.Range`
- `scratchbird.RawValue`

## Errors

Exceptions follow the DB-API hierarchy and map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).

Query and DDL errors now drain the statement's trailing protocol boundary
before the exception is raised. A subsequent `rollback()` or `execute()` on the
same connection does not require a reconnect just to recover from a statement
error.
