# Swift Async/Await Driver Specification (ScratchBird)

Status: P1
Last Updated: 2026-01-30

## Goal

Provide a native Swift driver that uses Swift Concurrency (async/await) and
speaks ScratchBird Wire Protocol (SBWP v1.1) in binary-only mode.

Target users:
- iOS/macOS apps
- Server-side Swift (Vapor, Hummingbird, custom services)

## Package Layout

- Swift Package: `ScratchBirdSwift`
- Modules:
  - `ScratchBird` (public API)
  - `ScratchBirdCore` (protocol + encoding/decoding)
  - `ScratchBirdNIO` (default transport using SwiftNIO)
  - `ScratchBirdNetwork` (optional transport using Network.framework)

## Dependencies

- Swift 5.9+
- SwiftNIO (default transport)
- NIOExtras (optional TLS helpers)

## Configuration

Expose a `ScratchBird.Configuration`:

- host, port (default 3092)
- database, user, password
- sslmode, sslrootcert, sslcert, sslkey, sslpassword
- connectTimeout, socketTimeout
- applicationName, searchPath, role
- binaryTransfer (must be true)
- compression (off|zstd)
- fetchSize

DSN formats must match `docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md`.
Explicit config overrides DSN values.

## API Surface

- `ScratchBird.Connection.connect(configuration:) async throws -> Connection`
- `Connection.query(_ sql: String, _ params: [Value]) async throws -> ResultSet`
- `Connection.prepare(_ sql: String) async throws -> Statement`
- `Statement.execute(_ params: [Value]) async throws -> ResultSet`
- `Connection.transaction { ... }`
- `Connection.stream(_ sql: String, _ params: [Value]) -> AsyncThrowingStream<Row, Error>`
- `Connection.cancel(_ handle: QueryHandle) async`

All queries must use server-side prepare/bind.

## Transactions

- Support nested transactions via savepoints.
- Provide `TransactionOptions` (readOnly, isolationLevel, timeoutSeconds).
- Map rollback to protocol abort.

## Type Mapping

Swift types -> ScratchBird types:

- `Int`, `Int32`, `Int64` -> INT32/INT64
- `Double`, `Float` -> DOUBLE/FLOAT
- `Decimal` -> DECIMAL/NUMERIC
- `Bool` -> BOOL
- `UUID` -> UUID
- `String` -> TEXT/VARCHAR
- `Data` -> BLOB/BYTEA
- `Date` -> TIMESTAMP (UTC)
- `DateComponents` -> DATE/TIME

Wrapper types:

- `ScratchBird.Types.Jsonb`
- `ScratchBird.Types.Range`
- `ScratchBird.Types.Geometry`

## Error Handling

Errors conform to:

- `ScratchBirdError` with `sqlstate`, `code`, `message`, `detail`
- Map SQLSTATE per `DRIVER_ERROR_MAPPING.md`

## Observability

- Always send `application_name` on startup.
- Expose `Connection.serverVersion` and `Connection.backendId`.

## Conformance Tests

- Use `SCRATCHBIRD_TEST_DSN`.
- Run shared SQL fixtures from `docs/fixtures/`.
- Validate:
  - handshake/auth
  - prepare/bind
  - type encoding/decoding
  - streaming/paging

## Deliverables

- Swift Package Manager release.
- API docs with async/await examples.
- Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
