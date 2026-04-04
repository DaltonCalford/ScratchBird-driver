# Mojo Native Driver Specification (ScratchBird)

Status: Hybrid surface-complete / native transport gap outstanding
Last Updated: 2026-04-03

## Implementation Status

- Current lane verdict: baseline surface is marked implemented in `tracks/p3/drivers/mojo/BASELINE_REQUIREMENT_MAPPING.md`, but the lane is not yet fully closed as a native driver.
- Source of truth:
  - `tracks/p3/drivers/mojo/BASELINE_REQUIREMENT_MAPPING.md`
  - `tracks/p3/drivers/mojo/README.md`
  - `docs/planning/driver-checklists/mojo.md`
- Outstanding architectural gap:
  - replace the Python bridge with a native SBWP client / native Mojo socket and TLS transport
- Important note:
  - this lane should not be described as fully complete while `tracks/p3/drivers/mojo/README.md` still states that native Mojo transport/auth remains future work and the checklist item to replace the Python bridge remains open.

## Goal

Provide a native Mojo driver for ScratchBird to support low-latency binary
protocol access (SBWP v1.1) for general application workloads.

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
- Publish release evidence per `DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`.

## Deliverables

- `scratchbird_mojo` package with minimal examples.
- Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
- Release evidence pack with compatibility, performance, known-gap, and
  packaging/cadence artifacts.

<!-- mojo-server-independent-closure:start -->

## Competitive Closure Status

- Selected benchmark: `Composite (asyncpg + pgx + PostgresNIO)`
- Current state: `hybrid_native_gap`
- Track root: `tracks/p3/drivers/mojo`

Competitive closure targets:

- promote native transport cutover from checklist work to a hard competitive-closure requirement
- require composite benchmark evidence after native transport lands

Remaining implementation or proof deltas:

- architectural gap: replace the Python bridge with a native SBWP client / native Mojo transport
- full live evidence remains blocked until native transport is implemented and a server is available

## Release Evidence And Later Verification

Release evidence path:

- `release/readiness/mojo/<version>/`

Shared evidence templates:

- `docs/development/release-evidence/README.md`

Later server-verification packet:

- `docs/development/server-verification/mojo.md`

Required environment inputs:

- `SCRATCHBIRD_MOJO_URL`
- `MOJO_ENABLED`

Build/bootstrap commands:

- `cd tracks/p3/drivers/mojo/tests`

Verification commands:

- `mojo integration.mojo`

<!-- mojo-server-independent-closure:end -->
