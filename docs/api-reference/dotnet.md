# .NET Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `Npgsql`
- Authoritative lane spec: `docs/specifications/drivers/language/dotnet-csharp/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/dotnet.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Assembly

- Namespace: `ScratchBird.Data`
- Provider: `ScratchBirdConnection`, `ScratchBirdCommand`

## Core Types

- `ScratchBirdConnection` (DbConnection)
- `ScratchBirdCommand` (DbCommand)
- `ScratchBirdParameter` (DbParameter)
- `ScratchBirdDataReader` (DbDataReader)
- `ScratchBirdTransaction` (DbTransaction)
- `ScratchBirdConnectionStringBuilder`
- `ScratchBirdQueryPipeline`
- `ScratchBirdQueryPipelineConfig`
- `ScratchBirdQueryPipelineBatch`
- `ScratchBirdPipelineBatchItem`
- `ScratchBirdTransactionOptions`
- `DdlEditorSchemaPayload`, `DdlEditorSchemaNode`
- `ScratchBirdFactory`

## Wrapper Types

- `ScratchBirdJson`
- `ScratchBirdJsonb`
- `ScratchBirdGeometry`
- `ScratchBirdRange<T>`
- `ScratchBirdInterval`, `ScratchBirdDate`, `ScratchBirdTime`,
  `ScratchBirdTimeTz`, `ScratchBirdTimestamp`, `ScratchBirdTimestampTz`, `ScratchBirdDecimal`,
  `ScratchBirdMoney`
- `ScratchBirdRaw`

## SBWP v1.1 Extensions

Advanced protocol operations are exposed on the internal `ProtocolClient`
owned by `ScratchBirdConnection`:

- `Begin()`, `Commit()`, `Rollback()`
- `Begin(ScratchBirdTransactionOptions)` with optional access/deferrable/wait/timeout/autocommit txn flags
- `Savepoint(name)`, `ReleaseSavepoint(name)`, `RollbackToSavepoint(name)`
- `SetOption(name, value)`
- `Ping()`
- `Subscribe(type, channel, filterExpr)`, `Unsubscribe(channel)`
- `ExecuteSblr(hash, bytecode, parameters, timeoutMs, maxRows)`
- `StreamControl(controlType, windowSize, timeoutMs)`
- `AttachCreate(emulationMode, dbName)`, `AttachDetach()`, `AttachList()`
- `OnNotification(handler)`
- `LastPlan`, `LastSblr`
- `Cancel()`

## Metadata

- `GetSchema(collectionName, restrictionValues)` supports extended metadata families (including unified `Routines`) and collection-scoped restriction filtering.
- Metadata restriction values support explicit `"null"` literal matching for nullable metadata columns.
- Metadata restrictions treat escaped wildcards as literals (`\%`, `\_`).
- `GetDdlEditorSchemaPayload(schemaPattern, expandSchemaParents)` returns schema paths plus hierarchical tree nodes for DDL/editor UX.

## Diagnostics

- `ScratchBirdConnection.GetDiagnostics()` returns a `ConnectionDiagnosticsSummary` snapshot with:
  - connection state and health
  - sanitized endpoint/mode fields (`FrontDoorMode`, `Protocol`, `Host`, `Port`, `Database`)
  - optional pooled counters (`PoolDiagnosticsSummary`) when pooling is enabled and a pool exists
  - latest server diagnostics payloads (`QueryPlanSummary`, `SblrSummary`) when available
  - current circuit-breaker status (`CircuitBreakerSummary`)
  - current keepalive status (`KeepaliveSummary`)
  - current pipeline-capacity status (`PipelineSummary`)
  - current leak-detection status (`LeakSummary`)
- `ScratchBirdConnection.GetPoolDiagnostics()` returns pooled counters for the current connection configuration.
- `ScratchBirdConnection.GetPoolDiagnostics(connectionString)` provides static access to pool counters without opening a connection.
- `ScratchBirdConnection.GetCircuitBreakerSummary()` returns the live circuit-breaker snapshot.
- Circuit-breaker DSN controls: `cb_failure_threshold`, `cb_recovery_timeout_ms`, `cb_success_threshold`, `cb_half_open_max_requests` (disabled when failure threshold is `0`).
- `ScratchBirdConnection.GetKeepaliveSummary()` returns the keepalive monitor snapshot.
- Keepalive DSN controls: `keepalive_interval_ms`, `keepalive_max_idle_before_check_ms` (alias `keepalive_max_idle_ms`), `keepalive_validation_timeout_ms`.
- `ScratchBirdConnection.GetPipelineSummary()` returns the pipeline-capacity monitor snapshot.
- Pipeline DSN controls: `pipeline_max_in_flight` (disabled when set to `0`), `pipeline_auto_flush`, `pipeline_auto_flush_threshold`, `pipeline_flush_timeout_ms`.
- `ScratchBirdConnection.GetLeakSummary()` returns the leak monitor snapshot.
- Leak DSN controls: `leak_threshold_ms`, `leak_capture_stack` (alias `leak_capture_stack_trace`).

## Query Pipeline

- `ScratchBirdConnection.CreateQueryPipeline(config)` creates a single-worker query pipeline similar to JDBC `QueryPipeline`.
- `ScratchBirdConnection.ExecutePipelineBatchAsync(items, config, cancellationToken)` executes a one-shot pipelined batch and handles pipeline lifecycle automatically.
- `ScratchBirdQueryPipeline.QueueAsync(...)` enqueues SQL for asynchronous execution and returns `Task<IReadOnlyList<ResultSetSummary>>`.
- `ScratchBirdQueryPipeline.CreateBatch()` creates a fluent batch builder (`ScratchBirdQueryPipelineBatch`).
- `ScratchBirdQueryPipeline.ExecuteBatchAsync(items, cancellationToken)` executes an `IReadOnlyList<ScratchBirdPipelineBatchItem>` convenience batch.
- `ScratchBirdQueryPipeline.Flush()` triggers immediate processing of queued requests.
- `ScratchBirdQueryPipeline.PendingCount`, `InFlightCount`, and `HasCapacity` expose runtime queue/capacity state.
- `ScratchBirdQueryPipelineBatch.Add(...)` appends queued statements and returns the same builder for chaining.
- `ScratchBirdQueryPipelineBatch.ExecuteAsync()` enqueues the full batch atomically, flushes once, and returns ordered per-statement results.
- `ScratchBirdQueryPipelineConfig` controls queue behavior:
  - `MaxInFlight`
  - `AutoFlush`
  - `AutoFlushThreshold`
  - `FlushTimeoutMs`

## Telemetry

- `ScratchBirdConnection.GetTelemetrySummary()` returns aggregated per-operation metrics for this connection.
- `ScratchBirdConnection.ResetTelemetry()` clears recorded telemetry counters.
- `ScratchBirdConnection.GetSlowOperations()` returns the retained slow-operation ring buffer (`SlowOperationSummary`).
- `ScratchBirdConnection.ExportTelemetryPrometheus()` exports counters/histogram metrics in Prometheus text format.
- `ConnectionTelemetrySummary` includes total invocation/success/failure counts plus `OperationTelemetrySummary` entries.
- `SlowOperationSummary` includes `Operation`, `DurationMs`, `Success`, `CapturedUtc`, and optional `Statement` text.
- Command paths report operation names such as `Command.ExecuteReader`, `Command.ExecuteNonQuery`, and `Command.ExecuteScalar`.
- Slow-operation statement text is SQL-literal sanitized by default (`'...'` => `'?'`); set `TelemetrySanitizeStatements=false` to preserve raw SQL text.
- DSN/connection-string telemetry controls: `TelemetryEnableTracing`, `TelemetryEnableMetrics`, `TelemetryEnableSlowOperationLog`, `TelemetrySlowOperationThresholdMs`, `TelemetrySlowOperationMaxEntries`, `TelemetrySampleRate`, `TelemetrySanitizeStatements`.

## Notifications

- `ScratchBirdConnection.Listen(channel, filterExpr)` subscribes to channel notifications (`ScratchBirdSubscriptionType.Channel`).
- `ScratchBirdConnection.Unlisten(channel)` unsubscribes from a channel.
- `ScratchBirdConnection.UnlistenAll()` unsubscribes from all channels.
- `ScratchBirdConnection.Subscribe(subscriptionType, channel, filterExpr)` subscribes using `ScratchBirdSubscriptionType` (`Channel`, `Table`, `Query`, `Event`).
- `ScratchBirdConnection.Unsubscribe(channel)` unsubscribes by channel key.
- `ScratchBirdConnection.NotifyChannel(channel)` sends `NOTIFY` without payload.
- `ScratchBirdConnection.NotifyChannel(channel, string payload)` sends UTF-8 text payload.
- `ScratchBirdConnection.NotifyChannel(channel, byte[] payload)` sends binary payload converted as UTF-8 text.
- `ScratchBirdConnection.AddNotificationListener(Action<ScratchBirdNotification>)` registers a callback for asynchronous server notifications.
- `ScratchBirdConnection.RemoveNotificationListener(Action<ScratchBirdNotification>)` removes a callback and returns whether removal occurred.
- `ScratchBirdConnection.GetNotification()` dequeues one pending notification (or `null` when none are queued).
- `ScratchBirdConnection.GetNotifications()` drains all pending notifications as an immutable snapshot list.
- `ScratchBirdConnection.ClearNotifications()` clears queued notifications without invoking callbacks.
- `ScratchBirdNotification` fields: `ProcessId`, `Channel`, `Payload`, `ChangeType`, `RowId`, `ReceivedUtc`.

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
