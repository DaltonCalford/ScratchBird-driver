# .NET Driver API Reference

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
- `ScratchBirdFactory`

## Wrapper Types

- `ScratchBirdJson`
- `ScratchBirdJsonb`
- `ScratchBirdGeometry`
- `ScratchBirdRange<T>`
- `ScratchBirdInterval`, `ScratchBirdDate`, `ScratchBirdTime`,
  `ScratchBirdTimestamp`, `ScratchBirdTimestampTz`, `ScratchBirdDecimal`,
  `ScratchBirdMoney`
- `ScratchBirdRaw`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
