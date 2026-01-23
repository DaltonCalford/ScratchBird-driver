# Node.js Driver API Reference

## Package

- NPM package: `scratchbird`
- Main exports: `Client`, `Pool`

## Client

- `new Client(config | dsn)`
- `connect()`
- `query(sql, params?, options?)`
- `queryStream(sql, params?, options?)` -> async generator
- `prepare(name, sql)`
- `execute(name, params?, options?)`
- `begin()`, `commit()`, `rollback()`
- `end()`

### Query Options

- `signal` (AbortSignal)
- `maxRows`
- `timeoutMs`

## Pool

- `new Pool(config | dsn)`
- `connect()`
- `query(sql, params?, options?)`
- `end()`

## Parameters

Supports positional arrays or named parameter objects (`:name` or `@name` in SQL).

## Wrapper Types

- `ScratchbirdJson`
- `ScratchbirdJsonb`
- `ScratchbirdGeometry`
- `ScratchbirdRange<T>`
- `ScratchbirdRaw`
- `ScratchbirdInterval`, `ScratchbirdDate`, `ScratchbirdTime`,
  `ScratchbirdTimestamp`, `ScratchbirdTimestampTZ`, `ScratchbirdDecimal`,
  `ScratchbirdMoney`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
