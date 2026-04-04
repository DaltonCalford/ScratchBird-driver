# Rust Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `tokio-postgres`
- Authoritative lane spec: `docs/specifications/drivers/language/rust/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/rust.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Crate

- Crate name: `scratchbird`

## Entry Points

- `Config::from_dsn(dsn)`
- `Client::new(config)`
- `client.connect().await` / `client.close().await`

## Query And Execution Surfaces

- `client.query(sql).await` -> `QueryResult`
- `client.query_params(sql, params).await`
- `client.query_stream(sql).await` / `client.query_stream_params(...)`
- `client.native_sql(sql, params)` / `client.native_callable_sql(sql, params)`
- `client.call(sql, params).await`
- `client.query_multi(...)`, `client.execute_multi(...)`
- `client.execute_batch(...)`, `client.query_batch(...)`
- `client.execute_with_generated_keys(...)`

## Transactions And Session

- `client.autocommit()`, `client.set_autocommit(enabled).await`
- `client.begin(options).await`, `client.commit(options).await`,
  `client.rollback(options).await`
- aliases: `begin_transaction`, `commit_transaction`, `rollback_transaction`
- `client.savepoint(name).await`,
  `client.release_savepoint(name).await`,
  `client.rollback_to_savepoint(name).await`
- `client.set_option(name, value).await`
- `client.ping().await`, `client.terminate().await`, `client.cancel().await`

## Metadata

- `client.query_metadata(collection).await`
- `client.query_metadata_with_restrictions(collection, restrictions).await`
- `client.get_schema(collection, restrictions).await`
- `client.get_schema_tree(options).await`
- `client.ddl_editor_schema_payload(schema_pattern, expand_schema_parents).await`
- `Client::metadata_collection_name(collection)`

## Notifications And Protocol Extensions

- `client.subscribe(subscribe_type, channel, filter_expr).await`
- `client.unsubscribe(channel).await`
- `client.on_notification(handler)`
- `client.last_query_plan()`, `client.last_sblr_compiled()`
- `client.execute_sblr(hash, bytecode, params).await`
- `client.stream_control(control_type, window_size, timeout_ms).await`
- `client.attach_create(emulation_mode, db_name).await`,
  `client.attach_detach().await`, `client.attach_list().await`

## Copy And Bulk Data

- `client.copy_in(sql, data, options).await`
- `client.copy_out(sql, options).await`
- `client.copy_in_streaming(...)`
- `client.send_copy_data(...)`, `client.send_copy_done()`,
  `client.send_copy_fail(...)`

## Pooling, Retry, And Pipeline

- `ConnectionPool`, `PoolConfig`, `PooledConnection`, `PoolStats`
- `RetryConfig`, `with_retry`
- `PipelineConfig`, `QueryPipeline`, `PipelineBuilder`, `PipelineStats`

## Telemetry And Resilience

- `TelemetryCollector`, `TelemetryConfig`, `Metrics`,
  `OperationMetrics`, `SlowQueryLog`, `export_prometheus_metrics`
- `CircuitBreaker`, `CircuitBreakerConfig`, `CircuitBreakerStats`,
  `with_circuit_breaker`
- `KeepaliveConfig`, `KeepaliveTask`, `KeepaliveTracker`
- `LeakDetector`, `LeakDetectionConfig`, `LeakStatistics`

## Wrapper Types

- `Json`, `Jsonb`
- `Geometry`
- `Range<T>`, `RangeValue`
- `Interval`, `Date`, `Time`, `Timestamp`, `TimestampTz`
- `Decimal`, `Money`
- `RawValue`
- `Param`, `Value`, `Composite`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
