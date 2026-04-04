# Dart Database API Specification (ScratchBird)

Status: Partial
Last Updated: 2026-04-03

## Implementation Status

- Current lane verdict: partial against the lane-local JDBC/.NET-class baseline mapping.
- Source of truth: `tracks/p3/drivers/dart/BASELINE_REQUIREMENT_MAPPING.md`
- Outstanding baseline gaps:
  - `TXN`: live server-side failure-path validation is still missing.
  - `EXEC`: live pagination / `portalSuspended` and SBLR execution coverage is still missing.
  - `META`: live restrictions, wildcard handling, and DDL-editor payload coverage is still missing.
  - `TYPE`: live complex-type binary roundtrip coverage is still missing.
  - `ERR`: live SQLSTATE/code propagation coverage is still missing.
  - `RES`: live resilience cleanup and idle-validation coverage is still missing.

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
- Publish release evidence per `DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`.

## Deliverables

- Pub package.
- Flutter usage examples.
- Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
- Release evidence pack with compatibility, performance, known-gap, and
  packaging/cadence artifacts.

<!-- dart-server-independent-closure:start -->

## Competitive Closure Status

- Selected benchmark: `postgres (Dart)`
- Current state: `partial`
- Track root: `tracks/p3/drivers/dart`

Competitive closure targets:

- freeze async ergonomics, metadata, and codec expectations against postgres(Dart)
- promote live metadata and failure-path validation from optional to required release evidence

Remaining implementation or proof deltas:

- TXN: live failure-path validation remains open
- EXEC: live pagination, portalSuspended, and SBLR execution proof remains open
- META: live restrictions, wildcard handling, and DDL-editor payload coverage remains open
- TYPE: live complex-type binary roundtrip coverage remains open
- ERR: live SQLSTATE/code propagation proof remains open
- RES: live resilience cleanup and idle-validation proof remains open

## Release Evidence And Later Verification

Release evidence path:

- `release/readiness/dart/<version>/`

Shared evidence templates:

- `docs/development/release-evidence/README.md`

Later server-verification packet:

- `docs/development/server-verification/dart.md`

Required environment inputs:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

Build/bootstrap commands:

- `cd tracks/p3/drivers/dart`
- `dart pub get`

Verification commands:

- `dart test`

<!-- dart-server-independent-closure:end -->
