# Go Driver API Reference

## Package

- Module: `github.com/scratchbird/scratchbird-go`
- Driver name for `database/sql`: `scratchbird`

## Entry Points

- `sql.Open("scratchbird", dsn)`
- `scratchbird.ParseConfig(dsn)` -> `scratchbird.Config`
- Exported connection helpers: `Conn`, `Stmt`, `Tx`, `Rows`, `Result`

## Config

`Config` normalizes canonical DSN keys and lane-specific parity options,
including:

- endpoint/session: `Host`, `Port`, `Database`, `User`, `Password`,
  `ApplicationName`, `FetchSize`
- security/transport: `SSLMode`, `SSLRootCert`, `SSLCert`, `SSLKey`,
  `BinaryTransfer`, `Compression`
- managed/auth plugin: `FrontDoorMode`, `ManagerAuthToken`,
  `ManagerConnectionProfile`, `ManagerClientIntent`, `ManagerClientFlags`,
  `ConnectClientFlags`, `AuthMethodPayload`, `AuthRequiredMethods`,
  `AuthForbiddenMethods`, `AuthRequireChannelBinding`,
  `WorkloadIdentityToken`, `ProxyPrincipalAssertion`

## `*Conn`

Database/sql and extended query surfaces:

- `PrepareContext`, `ExecContext`, `QueryContext`, `Ping`
- `NativeSQL`, `NativeCallableSQL`, `CallContext`
- `QueryMultiContext`, `ExecuteMultiContext`
- `ExecuteBatchContext`, `QueryBatchContext`
- `ExecuteWithGeneratedKeysContext`
- `BatchInsert`

Transactions and session:

- `Begin`, `BeginTx`
- `Savepoint`, `ReleaseSavepoint`, `RollbackToSavepoint`
- `SetOption`, `ResetSession`

Metadata:

- `QueryMetadata`
- `QueryMetadataWithRestrictions`

Notifications and protocol extensions:

- `Subscribe`, `Unsubscribe`
- `OnNotification`
- `LastPlan`, `LastSblr`
- `QuerySblr`, `ExecSblr`
- `StreamControl`
- `AttachCreate`, `AttachDetach`, `AttachList`
- `CopyIn`, `CopyOut`
- `IsHealthy`, `Close`

## Query Pipeline

- `PipelineConfig`
- `DefaultPipelineConfig()`
- `NewQueryPipeline(config)`
- `QueryPipeline.Start`, `Stop`, `Queue`, `PendingCount`, `InFlightCount`,
  `HasCapacity`, `Flush`
- `PipelineBuilder`

## Telemetry And Resilience

- `TelemetryCollector`, `TelemetryConfig`, `MetricsSnapshot`,
  `SlowQueryLog`, `ExportPrometheusMetrics`
- `CircuitBreaker`, `CircuitBreakerConfig`, `CircuitBreakerStats`
- `KeepaliveManager`, `KeepaliveTracker`
- `LeakDetector`, `LeakStats`

## Wrapper Types

Use these types for complex values:

- `JSON`, `JSONB`
- `Geometry`
- `Range[T]`
- `Interval`, `Date`, `Time`, `TimeTZ`, `Timestamp`, `TimestampTZ`
- `Decimal`, `Money`
- `RawValue`, `Composite`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
