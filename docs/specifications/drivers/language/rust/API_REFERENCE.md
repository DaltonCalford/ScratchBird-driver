# Rust Driver API Reference (Template)

Status: Draft (Template)

## Connection

- `connect(options)`
- `close()`

## Queries

- `query(sql, params)`
- `execute(sql, params)`
- `prepare(sql)`

## Transactions

- `begin()`
- `commit()`
- `rollback()`

## Metadata

- `schemas()`
- `tables(schema)`
- `columns(schema, table)`
- `indexes(schema, table)`

## Errors

All errors must include message + SQLSTATE + detail + hint when available.
