# C/C++ Client API Reference

## Public Headers

- `scratchbird/client/scratchbird_client.h`
- `scratchbird/client/connection.h`
- `scratchbird/client/pool.h`
- `scratchbird/client/pipeline.h`

## C API

Connection and execution:

- `sb_connect`, `sb_disconnect`
- `sb_execute`, `sb_query`
- `sb_prepare`, `sb_bind_index`, `sb_bind_name`, `sb_execute_prepared`
- `sb_cancel`, `sb_set_option`, `sb_ping`, `sb_is_healthy`

Result handling:

- `sb_fetch`, `sb_result_free`, `sb_rows_affected`
- `sb_column_count`, `sb_get_column_meta`
- `sb_value_get`, `sb_get_int64`, `sb_get_string`
- `sb_memory_free`

Transactions and savepoints:

- `sb_tx_begin`, `sb_tx_begin_ex`
- `sb_tx_commit`, `sb_tx_rollback`
- `sb_tx_savepoint`, `sb_tx_release_savepoint`, `sb_tx_rollback_to`

Metadata and schema payloads:

- `sb_metadata_query`
- `sb_metadata_schema_payload`

Notifications:

- `sb_subscribe`, `sb_unsubscribe`
- `sb_listen`, `sb_unlisten`, `sb_unlisten_all`
- `sb_notify_channel`
- `sb_poll_notifications`, `sb_notification_count`
- `sb_get_notification`, `sb_get_notifications`, `sb_clear_notifications`
- `sb_add_notification_listener`, `sb_remove_notification_listener`

Diagnostics and telemetry:

- `sb_get_diagnostics_json`
- `sb_get_telemetry_summary_json`, `sb_reset_telemetry`
- `sb_get_slow_operations_json`, `sb_export_telemetry_prometheus`
- `sb_get_circuit_breaker_summary_json`
- `sb_get_keepalive_summary_json`
- `sb_get_leak_summary_json`

Protocol extensions:

- `sb_stream_control`
- `sb_attach_create`, `sb_attach_detach`, `sb_attach_list`
- `sb_execute_sblr`

## C++ Wrapper Surface

Namespace: `scratchbird::client`

- `ConnectionConfig`
- `Connection`
- `PreparedStatement`
- `ResultSet`
- `ConnectionPool`
- `ConnectionLease`

`Connection` provides:

- `connect(...)`, `disconnect()`, `isConnected()`, `getState()`
- `executeQuery(...)`, `execute(...)`
- `prepare(...)`
- `metadataQuery(...)`, `schemas(...)`, `tables(...)`, `columns(...)`,
  `indexes(...)`, `metadataSchemaPayload(...)`
- `beginTransaction()`, `commit()`, `rollback()`
- `savepoint()`, `releaseSavepoint()`, `rollbackTo()`
- `setAutoCommit()`, `getAutoCommit()`, `inTransaction()`

Connection-config helpers:

- `parseConnectionConfig(...)` parses URI/key-value DSNs into the public
  `ConnectionConfig` surface, including listener-bound manager-proxy, schema,
  role, TLS, and compression options.

`PreparedStatement` provides:

- typed setters mirroring the network prepared-statement surface
- `executeQuery(...)`
- `execute(...)`

## Pooling And Retry

In `pool.h`:

- `sb_pool_create`, `sb_pool_destroy`
- `sb_pool_acquire`, `sb_pool_release`, `sb_pool_get_stats`
- `sb_query_with_retry`, `sb_execute_with_retry`
- `sb_batch_execute`, `sb_bulk_insert`
- `sb_stmt_cache_create`, `sb_stmt_cache_get`, `sb_stmt_cache_clear`

C++ pooling helpers:

- `ConnectionPool::open(...)`, `close()`, `stats()`, `acquire()`
- `ConnectionLease::query(...)`, `execute(...)`, `raw()`, `reset()`

## Query Pipeline

In `pipeline.h`:

- C API: `sb_pipeline_create`, `sb_pipeline_start`, `sb_pipeline_flush`,
  `sb_pipeline_pending_count`, `sb_pipeline_has_capacity`, `sb_pipeline_stop`
- C++ API: `scratchbird::client::Pipeline`

## Value And Type Helpers

Core value containers:

- `sb_error`, `sb_value`, `sb_column_meta`, `sb_txn_options`
- `sb_type` includes scalar, temporal, JSON/JSONB, geometry, range, array,
  composite, vector, and network types.
- `ResultSet` column metadata now carries mapped `sb_type`, `type_oid`,
  binary/text format, and nullability.

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
