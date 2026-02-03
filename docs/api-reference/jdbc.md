# JDBC Driver API Reference

## Driver

- Driver class: `com.scratchbird.jdbc.SBDriver`
- JDBC URL: `jdbc:scratchbird://host:3092/database`

## Core Types

- `SBConnection` implements `java.sql.Connection`
- `SBStatement`, `SBPreparedStatement`, `SBCallableStatement`
- `SBResultSet`, `SBResultSetMetaData`
- `SBDatabaseMetaData`

## Wrapper Types

- `SBJsonb`
- `SBGeometry`
- `SBRange<T>`
- `SBRawValue`

## SBWP v1.1 Extensions

ScratchBird-specific helpers:

- `SBConnection.cancelQuery()`
- `SBProtocolHandler` (internal) exposes:
  - `beginTransaction(...)`, `commitTransaction(flags)`, `rollbackTransaction(flags)`
  - `savepoint(name)`, `releaseSavepoint(name)`, `rollbackToSavepoint(name)`
  - `setOption(name, value)`
  - `ping()`
  - `subscribe(type, channel, filterExpr)`, `unsubscribe(channel)`
  - `executeSblr(hash, bytecode, params, paramTypes)`
  - `streamControl(controlType, windowSize, timeoutMs)`
  - `attachCreate(emulationMode, dbName)`, `attachDetach()`, `attachList()`
  - `addNotificationListener(handler)`
  - `getLastQueryPlan()`, `getLastSblrCompiled()`

## Errors

SQLException SQLSTATE mapping follows
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
