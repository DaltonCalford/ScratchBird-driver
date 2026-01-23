# Rust Driver API Reference

## Crate

- Crate name: `scratchbird`

## Entry Points

- `Config::from_dsn(dsn)`
- `Client::new(config)`
- `client.connect().await` / `client.close().await`

## Queries

- `client.query(sql).await` -> `QueryResult`
- `client.query_stream(sql).await` -> `QueryStream`
- `client.prepare(name, sql).await`
- `client.execute(name, params).await`

## Parameters

Use `types::Param` for explicit type binding or pass supported native values.

## Wrapper Types

- `Json`, `Jsonb`
- `Geometry`
- `Range<T>`, `RangeValue`
- `Interval`, `Date`, `Time`, `Timestamp`, `TimestampTz`
- `Decimal`, `Money`
- `RawValue`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
