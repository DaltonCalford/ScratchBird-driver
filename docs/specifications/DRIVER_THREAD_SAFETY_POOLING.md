# Driver Thread Safety and Pooling

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define minimum thread-safety expectations and pooling guidance for drivers.

## Binary-Only Requirement

Pools must not mix binary and text protocol modes. All pooled connections
must operate in binary-only mode.

## Thread Safety

- Connection objects are not required to be thread-safe unless explicitly stated.
- Statement and result objects are not thread-safe.
- Drivers must document any safe concurrent usage patterns.

## Pooling

- Pooling is optional and driver-specific.
- If pooling is provided, it must be a separate component from a single
  connection object.
- Pools must honor max open and max idle settings.
- Pools must not return connections that are mid-transaction.

## SQLSTATE Codes (Pooling/Concurrency)

- 53300: too many connections
- 08004: server rejected connection

## Per-Language Guidance

### Go

- sql.DB is concurrency-safe; individual Conn and Rows are not.
- Pooling is provided by database/sql.

### Node.js/TypeScript

- Single client is not concurrency-safe across overlapping queries.
- Provide an explicit pool abstraction when needed.

### Python

- Connections and cursors are not thread-safe.
- Use per-thread connections or a pool library.

### Ruby

- Connections are not thread-safe.
- Use a pool if multi-threaded.

### Rust

- Client is not Sync by default; use one task per client.
- Provide pooling via a separate pool crate or module.

### PHP

- Connections are not thread-safe; process-based concurrency only.

### R

- Single-threaded by default; no shared connection across threads.

### Pascal/Delphi

- Connection objects are not thread-safe.
- Use one connection per thread.

### .NET

- DbConnection is not thread-safe; use one command per connection.
- Pooling is provided by ADO.NET.

### JDBC

- Connection and Statement objects are not thread-safe.
- Pooling should be external (HikariCP, etc.).
