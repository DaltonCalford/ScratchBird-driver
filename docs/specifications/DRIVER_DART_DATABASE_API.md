# Dart Database API Specification (ScratchBird)

Status: P2
Last Updated: 2026-01-30

## Goal

Provide a native Dart driver for ScratchBird with async/await APIs suitable
for Flutter (mobile/desktop) and server-side Dart.

## Package Layout

- Pub package: `scratchbird`
- Libraries:
  - `scratchbird` (public API)
  - `scratchbird/src/protocol` (SBWP v1.1)
  - `scratchbird/src/types` (encoding/decoding)

## Dependencies

- Dart 3.x
- No external native dependencies

## Configuration

Expose a `ScratchBirdConfig`:

- host, port (default 3092)
- database, user, password
- sslmode, sslrootcert, sslcert, sslkey, sslpassword
- connectTimeout, socketTimeout
- applicationName, searchPath, role
- binaryTransfer (must be true)
- compression (off|zstd)
- fetchSize

DSN parsing must follow `DRIVER_DSN_AND_CONFIG_STANDARD.md`.

## API Surface

- `ScratchBird.connect(ScratchBirdConfig config) -> Future<ScratchBirdConnection>`
- `ScratchBirdConnection.query(String sql, [List<Value> params])`
- `ScratchBirdConnection.prepare(String sql)`
- `ScratchBirdStatement.execute([List<Value> params])`
- `ScratchBirdConnection.transaction(Future<T> Function() action)`
- `ScratchBirdConnection.stream(String sql, [List<Value> params]) -> Stream<Row>`
- `ScratchBirdConnection.cancel(QueryHandle handle)`

All queries must use server-side prepare/bind (SBWP v1.1).

## Transactions

- Nested transactions use savepoints.
- Support `TransactionOptions` (readOnly, isolationLevel, timeoutSeconds).

## Type Mapping

Dart types -> ScratchBird types:

- `int` -> INT32/INT64
- `double` -> DOUBLE/FLOAT
- `Decimal` (package:decimal) -> DECIMAL/NUMERIC
- `bool` -> BOOL
- `String` -> TEXT/VARCHAR
- `Uint8List` -> BLOB/BYTEA
- `DateTime` -> TIMESTAMP (UTC)
- `Duration` -> TIME
- `UuidValue` (package:uuid) -> UUID

Wrapper types:

- `ScratchBirdJsonb`
- `ScratchBirdRange`
- `ScratchBirdGeometry`

## Error Handling

- `ScratchBirdException` with `sqlstate`, `code`, `message`, `detail`
- SQLSTATE mapping per `DRIVER_ERROR_MAPPING.md`.

## Observability

- Send `applicationName` on startup.
- Expose `serverVersion` and `backendId`.

## Conformance Tests

- Use `SCRATCHBIRD_TEST_DSN`.
- Execute fixtures in `docs/fixtures/`.

## Deliverables

- Pub package.
- Flutter usage examples.
- Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
