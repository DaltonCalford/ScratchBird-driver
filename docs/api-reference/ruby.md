# Ruby Driver API Reference

## Module

- Namespace: `Scratchbird`
- Entry point: `Scratchbird.connect(dsn_or_options)`

## Connection

- `query(sql, params = nil)` / `execute(sql, params = nil)`
- `stream(sql, params = nil)`
- `prepare(sql)` -> `Statement`
- `execute_prepared(name, params = nil)`, `stream_prepared(name, params = nil)`
- `close_prepared(name)`
- `begin_transaction`, `commit`, `rollback`
- `savepoint(name)`, `rollback_to_savepoint(name)`, `release_savepoint(name)`
- `native_sql(sql, params = nil)`, `native_callable_sql(sql, params = nil)`
- `call(sql, params = nil)`
- `query_multi(sql, params = nil)` / `execute_multi(sql, params = nil)`
- `execute_batch(sql, batch_params)` / `query_batch(sql, batch_params)`
- `execute_with_generated_keys(sql, params = nil)`
- `query_metadata(collection = "tables")`
- `query_metadata_with_restrictions(collection = "tables", restrictions = nil)`
- `get_schema(collection = "tables", expand_schema_parents: nil)`
- `get_schema_with_restrictions(collection = "tables", restrictions = nil, expand_schema_parents: nil)`
- `get_schema_tree(expand_schema_parents: nil, database: nil, default_branch: "default", restrictions: nil)`
- `autocommit` (boolean)
- `close`, `closed?`

## Statement

- `execute(params = nil)`
- `stream(params = nil)`
- `close`

## Results

- `Result`: `columns`, `rows`, `rowcount`, `command_tag`, `last_insert_id`, `each`, `each_hash`
- `ResultStream`: `columns`, `rowcount`, `command_tag`, `last_insert_id`, `each`, `each_hash`, `to_a`
- Batch/multi summaries: `FieldSummary`, `ResultSetSummary`, `BatchItemSummary`, `BatchSummary`

## SBWP v1.1 Extensions

Advanced protocol operations are exposed on `Scratchbird::Client` (via
`Connection#client`):

- `savepoint(name)`, `release_savepoint(name)`, `rollback_to_savepoint(name)`
- `set_option(name, value)`
- `ping`
- `subscribe(channel, sub_type = ..., filter_expr = "")`, `unsubscribe(channel)`
- `execute_sblr(hash, bytecode = nil, params = [])`
- `stream_control(control_type, window_size, timeout_ms)`
- `attach_create(emulation_mode, db_name)`, `attach_detach`, `attach_list`
- `on_notification { |notice| ... }`
- `last_plan`, `last_sblr`

## Supporting Modules

- `Scratchbird::Config`
- `Scratchbird::TelemetryCollector`
- `Scratchbird::CircuitBreaker`
- `Scratchbird::KeepaliveManager`
- `Scratchbird::LeakDetector`

## Parameters

Supports positional arrays or named parameter hashes (`:name` or `@name` in SQL).

## Wrapper Types

- `Scratchbird::JSONB`
- `Scratchbird::Geometry`
- `Scratchbird::RangeValue`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
