# JDBC Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `pgjdbc`
- Authoritative lane spec: `docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/jdbc.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Driver

- Driver class: `com.scratchbird.jdbc.SBDriver`
- JDBC URL: `jdbc:scratchbird://host:3092/database`
- Parsed configuration surface: `SBConnectionProperties`

`SBConnectionProperties` is the main typed property bag behind JDBC URLs and
`Properties`-based connects. It exposes the current ScratchBird JDBC
connection surface, including:

- direct and managed ingress (`front_door_mode=direct|manager_proxy`)
- TLS / `sslmode` controls
- compatibility startup settings such as `binary_transfer` and `compression`
- pooling and fetch-size controls
- optional `currentSchema`
- metadata expansion (`metadataExpandSchemaParents`)
- auth-plugin handshake inputs such as `connect_client_flags`,
  `auth_method_payload`, `auth_required_methods`,
  `auth_forbidden_methods`, `auth_require_channel_binding`,
  `workload_identity_token`, and `proxy_principal_assertion`

If `currentSchema` is omitted, the driver does not force a client-side default.
The resolved current schema comes from the server-side user/role/group schema
policy, and if that chain does not set a schema the server fallback is
`users.public`.

## Core Types

- `SBConnection` implements `java.sql.Connection`
- `SBStatement`, `SBPreparedStatement`, `SBCallableStatement`
- `SBResultSet`, `SBResultSetMetaData`, `SBParameterMetaData`
- `SBDatabaseMetaData`
- `SBSavepoint`
- `SBConnectionPool`, `SBConnectionPool.PoolConfig`, `SBConnectionPool.PoolStats`

## JDBC Object / Wrapper Types

- `SBArray`, `SBStruct`, `SBRef`, `SBRowId`
- `SBBlob`, `SBClob`, `SBNClob`, `SBSQLXML`
- `SBJsonb`
- `SBGeometry`
- `SBRange<T>`
- `SBRawValue`

## Connection Extensions

`SBConnection` provides standard JDBC behavior plus ScratchBird-specific
helpers beyond the `java.sql.Connection` contract:

- `cancelQuery()`
- notification queue and listener lifecycle:
  - `addNotificationListener(listener)`
  - `removeNotificationListener(listener)`
  - `getNotification()`
  - `getNotifications()`
  - `clearNotifications()`
  - `listen(channel)`
  - `unlisten(channel)`
  - `unlistenAll()`
  - `notifyChannel(channel)`
  - `notifyChannel(channel, String payload)`
  - `notifyChannel(channel, byte[] payload)`
- connection inspection:
  - `getConnectionProperties()`
  - `getConnectionId()`

`getSchema()` returns the resolved live schema for the session. If
`currentSchema` was supplied explicitly, the driver applies it. Otherwise it
discovers the server-selected schema after connect.

ScratchBird sessions are always on a transaction boundary. `connect()`,
`commit()`, and `rollback()` leave the session immediately usable in the next
transaction context; toggling `autoCommit=false` does not inject an extra
`BEGIN` when the server already has an active transaction.

`SBConnection.Notification` exposes:

- `getProcessId()`
- `getChannel()`
- `getPayload()`
- `getPayloadText()`
- `getChangeType()`
- `getRowId()`

## Metadata

`SBDatabaseMetaData` implements the standard JDBC metadata surface and includes
the broader ScratchBird/JDBC parity families now used elsewhere in the repo.
Notable supported areas include:

- schemas, catalogs, tables, columns, indexes, primary keys, foreign keys
- procedures and procedure columns
- functions and function columns
- table and column privileges
- `getTypeInfo()`
- `getUDTs(...)`, `getSuperTypes(...)`, `getSuperTables(...)`
- `getAttributes(...)`
- `getPseudoColumns(...)`
- `getClientInfoProperties()`
- `supportsSavepoints()`
- `supportsRefCursors()`

When `metadataExpandSchemaParents=true` is configured, schema metadata expands
hierarchical parent paths during `getSchemas(...)`.

## Pooling

- Driver-managed pooling is available through `SBConnectionPool`.
- `SBDriver.getPoolStats(SBConnectionProperties)` returns the live
  `PoolStats` snapshot for a matching active pool.
- `PoolStats` exposes `available`, `total`, `max`, `hits`, `misses`, and
  `getHitRate()`.

Pooled connections are reset to baseline driver state before reuse, including
schema, `autoCommit`, isolation level, read-only flag, and pending manual
transaction rollback.

## Query Pipeline

`QueryPipeline<T>` is the public Java pipelining helper:

- `new QueryPipeline<>()`
- `start(connection)`
- `stop()`
- `queue(sql)`
- `queue(sql, params)`
- `getPendingCount()`
- `getInFlightCount()`
- `hasCapacity()`
- `flush()`

Queued operations return `CompletableFuture<T>`. The pipeline helper is a
single-worker async batching utility rather than a JDBC-standard abstraction.

## Advanced Protocol Surface

Advanced SBWP v1.1 operations are exposed on `SBProtocolHandler`. This is a
public class but is best treated as a lower-level driver API rather than the
primary JDBC entry point.

Key methods include:

- `connect()`, `close()`, `abort()`, `isConnected()`, `isAlive(timeout)`
- `execute(...)`, `executeNoCache(...)`, `executeStreaming(...)`
- `beginTransaction()`
- `beginTransaction(isolationLevel, accessMode, deferrable, waitPolicy, timeoutMs, commitFlags, rollbackFlags)`
- `commitTransaction(flags)`, `rollbackTransaction(flags)`
- `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
- `setOption(name, value)`
- `ping()`
- `subscribe(type, channel, filterExpr)`, `unsubscribe(channel)`
- `executeSblr(hash, bytecode, params, paramTypes)`
- `streamControl(controlType, windowSize, timeoutMs)`
- `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
- `cancelCurrentQuery()`
- `getLastQueryPlan()`, `getLastSblrCompiled()`

Raw protocol execution returns `SBQueryResult`, which exposes:

- `nextRow()`
- `getColumns()`
- `getUpdateCount()`
- `getCommandTag()`
- `isDone()`

## Telemetry And Resilience

The JDBC lane exposes telemetry and resilience as separate public helper
classes rather than high-level `SBConnection` snapshot methods:

- `TelemetryCollector`
  - `startSpan(name)`, `endSpan(span, success)`
  - `getMetrics()`
  - `getSlowQueries()`
  - `exportPrometheusMetrics()`
  - `sanitizeQuery(sql)`
- `CircuitBreaker`
  - `allowRequest()`
  - `recordSuccess()`, `recordFailure()`
  - `getState()`, `getStats()`
- `KeepaliveManager`
  - connection registration and periodic validation support
- `LeakDetector`
  - checkout tracking and `getStats()`

These helpers are used by the JDBC implementation itself and are also available
to advanced embedders working directly in `com.scratchbird.jdbc`.

## Errors

SQLException SQLSTATE mapping follows
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
