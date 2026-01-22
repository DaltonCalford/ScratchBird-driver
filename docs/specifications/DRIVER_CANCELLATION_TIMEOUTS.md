# Driver Cancellation and Timeouts

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define how drivers cancel running statements and enforce timeouts.

## Binary-Only Requirement

CANCEL is a binary SBWP message with MSG_FLAG_URGENT. Drivers must use the
binary CANCEL path and must not emulate cancellation by closing the socket
unless the server is unresponsive.

## Cancellation

- Drivers must send SBWP CANCEL with MSG_FLAG_URGENT.
- Cancellation should not terminate the connection.
- If the server closes the connection, drivers must surface a connection error.

## Timeouts

- connect_timeout applies to TCP/TLS startup.
- socket_timeout applies to read/write operations.
- statement timeouts must map to CANCEL where supported.

## SQLSTATE Codes (Cancel/Timeout)

- 57014: query canceled
- 57P01: admin shutdown
- 57P03: cannot connect now
- 08006: connection failure (timeout or disconnect)
- 08001: client cannot establish connection

## Per-Language Cancellation Mapping

### Go

- Use context cancellation on QueryContext/ExecContext.
- Expose Cancel via context or explicit cancel helper.

### Node.js/TypeScript

- Support AbortSignal on query methods.
- Provide client.cancel(requestId) or equivalent.

### Python

- Provide cursor.cancel() or connection.cancel().
- Map statement timeouts to OperationalError.

### Ruby

- Provide client.cancel() and statement cancel hooks.

### Rust

- Provide CancellationToken or abort handle for query futures.

### PHP

- Provide Connection->cancel() or Statement->cancel().

### R

- Provide sb_cancel(connection) or equivalent.

### Pascal/Delphi

- Provide Cancel on query/statement components.

### .NET

- Use CancellationToken for async methods and DbCommand.Cancel().

### JDBC

- Use Statement.cancel() and setQueryTimeout().

