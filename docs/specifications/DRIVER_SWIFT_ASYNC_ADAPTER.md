# Swift Async/Await Driver Specification (ScratchBird)

Status: Partial
Last Updated: 2026-04-03

## Implementation Status

- Current lane verdict: partial against the lane-local JDBC/.NET-class baseline mapping.
- Source of truth: `tracks/p3/drivers/swift/BASELINE_REQUIREMENT_MAPPING.md`
- Outstanding baseline gaps:
  - `EXEC`: live cancellation timing and portal suspend/resume behavior coverage is still missing.
  - `META`: full metadata family completeness beyond current schema/table/tree entry points is still missing.
  - `TYPE`: live advanced codec roundtrip coverage is still missing.
  - `ERR`: live auth/connect error propagation remains incomplete.
  - `RES`: wait-queue/timeout/fault-recovery pool semantics remain incomplete.

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
- Publish release evidence per `DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`.

## Deliverables

- Swift Package Manager release.
- API docs with async/await examples.
- Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
- Release evidence pack with compatibility, performance, known-gap, and
  packaging/cadence artifacts.

<!-- swift-server-independent-closure:start -->

## Competitive Closure Status

- Selected benchmark: `PostgresNIO`
- Current state: `partial`
- Track root: `tracks/p3/drivers/swift`

Competitive closure targets:

- freeze PostgresNIO-class async, pooling, and codec expectations
- require wait-queue, timeout, and fault-recovery evidence

Remaining implementation or proof deltas:

- EXEC: live cancellation timing and portal suspend/resume coverage remains open
- META: catalog payload families remain incomplete
- TYPE: advanced type roundtrip proof remains open
- ERR: auth/connect error propagation proof remains open
- RES: pool wait-queue, timeout, and fault-recovery semantics remain open

## Release Evidence And Later Verification

Release evidence path:

- `release/readiness/swift/<version>/`

Shared evidence templates:

- `docs/development/release-evidence/README.md`

Later server-verification packet:

- `docs/development/server-verification/swift.md`

Required environment inputs:

- `SCRATCHBIRD_TEST_DSN`

Build/bootstrap commands:

- `cd tracks/p3/drivers/swift`
- `swift build`

Verification commands:

- `swift test`

<!-- swift-server-independent-closure:end -->
