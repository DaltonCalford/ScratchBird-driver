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

## Errors

SQLException SQLSTATE mapping follows
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
