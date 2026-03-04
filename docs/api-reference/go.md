# Go Driver API Reference

## Package

- Module: `github.com/scratchbird/scratchbird-go`
- Driver name for `database/sql`: `scratchbird`

## Entry Points

- `sql.Open("scratchbird", dsn)`
- `scratchbird.ParseConfig(dsn)` -> `scratchbird.Config`

## Config

`Config` fields map to the canonical DSN keys:

- `Host`, `Port`, `Database`, `User`, `Password`
- `SSLMode`, `SSLRootCert`, `SSLCert`, `SSLKey`
- `ConnectTimeout`, `SocketTimeout`
- `Application`, `BinaryTransfer`, `Compression`

## Parameters

Supports positional `?` and named `:name` or `@name` placeholders. Parameters
are bound server-side.

## SBWP v1.1 Extensions

Advanced protocol operations are available on `*scratchbird.Conn` (driver.Conn):

- `SetOption(ctx, name, value)`
- `Ping(ctx)`
- `Subscribe(ctx, subType, channel, filter)`, `Unsubscribe(ctx, channel)`
- `OnNotification(handler)`
- `LastPlan()`, `LastSblr()`
- `QuerySblr(ctx, hash, bytecode, params)`, `ExecSblr(ctx, hash, bytecode, params)`
- `StreamControl(ctx, controlType, windowSize, timeoutMs)`
- `AttachCreate(ctx, emulationMode, dbName)`, `AttachDetach(ctx)`, `AttachList(ctx)`
- `QueryMetadata(ctx, collection)`, `QueryMetadataWithRestrictions(ctx, collection, restrictions)`

## Wrapper Types

Use these types for complex values:

- `JSON`, `JSONB`
- `Geometry`
- `Range[T]`
- `Interval`, `Date`, `Time`, `Timestamp`, `TimestampTZ`
- `Decimal`, `Money`
- `RawValue`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
