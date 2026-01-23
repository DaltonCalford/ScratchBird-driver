# R Driver API Reference

## Package

- Package: `scratchbird`
- DBI driver: `Scratchbird()`

## Core DBI Methods

- `dbConnect(Scratchbird(), dsn, ...)`
- `dbDisconnect(conn)`
- `dbGetQuery(conn, sql, ...)`
- `dbSendQuery(conn, sql, ...)` + `dbFetch()`
- `dbExecute(conn, sql, ...)`

## Wrapper Types

- `sb_jsonb()`
- `sb_geometry()`
- `sb_range()`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
