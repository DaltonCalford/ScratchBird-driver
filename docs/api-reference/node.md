# Node.js Driver API Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `node-postgres`
- Authoritative lane spec: `docs/specifications/drivers/language/nodejs-typescript/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/node.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Package

- NPM package: `scratchbird`
- Main exports: `Client`, `Pool`
- Supporting exports: `parseDsn`, `normalizeQuery`, `normalizeCallableQuery`,
  `normalizeCallableSql`, metadata helpers, typed errors, and resilience/telemetry modules

## Client

- `new Client(config | dsn)`
- `connect()`
- `query(sql, params?, options?)`
- `queryMulti(sql, params?, options?)`
- `queryBatch(sql, batchParams, options?)`
- `queryStream(sql, params?, options?)` -> async generator
- `prepare(name, sql)`
- `execute(name, params?, options?)`
- `executeMulti(name, params?, options?)`
- `executeBatch(name, batchParams, options?)`
- `executeWithGeneratedKeys(sql, params?, options?)`
- `nativeSQL(sql, params?)`, `nativeCallableSQL(sql, params?)`
- `call(sql, params?, options?)`
- `begin()`, `commit()`, `rollback()`
- `getAutoCommit()`, `setAutoCommit(enabled)`
- `getSessionSchema()`, `setSessionSchema(schema)`
- `queryMetadata(collectionName?, restrictions?)`
- `getSchema(collectionName?, restrictions?)`, `getSchemaTree(options?)`
- `end()`
- `terminate()`
- `beginTransaction()`, `commitTransaction()`, `rollbackTransaction()`
- `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
- `setOption(name, value)`
- `ping()`
- `subscribe(channel, options?)`, `unsubscribe(channel)`
- `executeSblr(hash, bytecode?, params?, options?)`
- `streamControl(controlType, windowSize?, timeoutMs?)`
- `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
- `onNotification(handler)`
- `getLastPlan()`, `getLastSblr()`

### Query Options

- `signal` (AbortSignal)
- `maxRows`
- `timeoutMs`
- `includePlan`
- `returnSblr`
- `describeOnly`
- `noCache`

## Pool

- `new Pool(config | dsn)`
- `connect()`
- `query(sql, params?, options?)`
- `end()`

## Supporting Modules

- `TelemetryCollector` plus telemetry summary/Prometheus export helpers
- `CircuitBreaker` / `CircuitBreakerConfig`
- `KeepaliveManager`
- `LeakDetector`

## Parameters

Supports positional arrays or named parameter objects (`:name` or `@name` in SQL).

## Wrapper Types

- `ScratchbirdJson`
- `ScratchbirdJsonb`
- `ScratchbirdGeometry`
- `ScratchbirdRange<T>`
- `ScratchbirdRaw`
- `ScratchbirdTypedValue` (explicit OID/value parameter encoding)
- `ScratchbirdInterval`, `ScratchbirdDate`, `ScratchbirdTime`,
  `ScratchbirdTimestamp`, `ScratchbirdTimestampTZ`, `ScratchbirdDecimal`,
  `ScratchbirdMoney`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
