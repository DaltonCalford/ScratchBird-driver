# Mojo Native Driver Specification (ScratchBird)

Status: P2
Last Updated: 2026-01-30

## Goal

Provide a native Mojo driver for ScratchBird to support AI/ML infrastructure
workloads with low-latency binary protocol access (SBWP v1.1).

## Constraints

- Mojo networking and async runtimes are evolving.
- Implementation must avoid unstable interfaces by isolating transport in a
  small module that can be replaced later.

## Package Layout

- Package: `scratchbird_mojo`
- Modules:
  - `scratchbird` (public API)
  - `scratchbird/protocol` (SBWP v1.1 encoding/decoding)
  - `scratchbird/transport` (TCP/TLS transport abstraction)

## Configuration

Expose `ScratchBirdConfig`:

- host, port (default 3092)
- database, user, password
- sslmode, sslrootcert, sslcert, sslkey, sslpassword
- connect_timeout_ms, socket_timeout_ms
- application_name, search_path, role
- binary_transfer (must be true)
- compression (off|zstd)
- fetch_size

DSN parsing must match `DRIVER_DSN_AND_CONFIG_STANDARD.md`.

## API Surface

Minimum API:

- `connect(config) -> Connection`
- `Connection.query(sql: String, params: List[Value]) -> ResultSet`
- `Connection.prepare(sql: String) -> Statement`
- `Statement.execute(params: List[Value]) -> ResultSet`
- `Connection.transaction(fn)`
- `Connection.stream(sql, params) -> Stream[Row]`
- `Connection.cancel(handle)`

All queries must use server-side prepare/bind.

## Transactions

- Nested transactions use savepoints.
- Support read-only and isolation-level options.

## Type Mapping

Mojo types -> ScratchBird types:

- `Int`, `Int64` -> INT32/INT64
- `Float64`, `Float32` -> DOUBLE/FLOAT
- `Bool` -> BOOL
- `String` -> TEXT/VARCHAR
- `Bytes` -> BLOB/BYTEA
- `UUID` -> UUID (string or 16-byte form)

Wrapper types:

- `Jsonb`
- `Range`
- `Geometry`

## Error Handling

- `ScratchBirdError` with `sqlstate`, `code`, `message`, `detail`
- SQLSTATE mapping per `DRIVER_ERROR_MAPPING.md`.

## Observability

- Always send `application_name` at startup.
- Expose server version and backend id.

## Conformance Tests

- Use `SCRATCHBIRD_TEST_DSN` when available.
- Execute shared fixtures in `docs/fixtures/`.

## Deliverables

- `scratchbird_mojo` package with minimal examples.
- Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
