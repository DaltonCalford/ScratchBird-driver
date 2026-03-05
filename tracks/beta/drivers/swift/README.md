# ScratchBird Swift Driver

Native ScratchBird driver using Swift Concurrency (async/await). SBWP v1.1,
binary-only transport.

## Lane Docs

- [Baseline Requirement Mapping (S0)](./BASELINE_REQUIREMENT_MAPPING.md)

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Not supported | Swift target/toolchain path is not configured for this repo. |
| macOS | Expected | SwiftPM workflow should work; not currently covered in CI. |

## Build (local dev)

```bash
cd swift
swift build
```

## Quick Start

```swift
import ScratchBird

let config = ScratchBirdConfig(dsn: "scratchbird://user:pass@localhost:3092/mydb")
let conn = try await ScratchBirdConnection.connect(config)
let result = try await conn.query("SELECT 1")
print(result.rows)
try await conn.close()
```

## TLS Note

TLS is required and implemented for ScratchBird connections.

- Apple and Linux: TLS transport uses `NIOSSL` whenever certificate files are
  supplied (`sslrootcert`, `sslcert`, `sslkey`), otherwise `Network` is used on
  Apple platforms.

`sslmode` supports: `disable` (rejected), `allow`, `prefer`, `require`,
`verify-ca`, and `verify-full`.

`sslkey`/`sslpassword` are currently loaded through NIOSSL when present.

## Error Model

Wire errors are mapped into typed Swift exceptions by SQLSTATE class/exact code:

- `ScratchBirdConnectionException`
- `ScratchBirdAuthorizationException`
- `ScratchBirdDataException`
- `ScratchBirdIntegrityException`
- `ScratchBirdTransactionException`
- `ScratchBirdProgrammingException`
- `ScratchBirdNotSupportedException`
- `ScratchBirdTimeoutException`
- `ScratchBirdOperationalException`

All typed exceptions carry structured fields (`sqlState`, `severity`, `detail`,
`hint`) and preserve `NSError` compatibility via `errorUserInfo`.

## Metadata Helpers

Connection-level metadata wrappers are available for `sys.*` catalog families:

- `metadataSchemas`, `metadataTables`, `metadataColumns`
- `metadataIndexes`, `metadataIndexColumns`, `metadataConstraints`
- `metadataProcedures`, `metadataFunctions`
- `metadataSchemaTree`, `metadataSchemaTreeRows`

## Execution Helpers

- `executeBatch(sql, paramsBatch)` for sequential batch execution helper semantics.
- `queryMulti(statements)` for multi-statement helper execution.
- `executeReturningFirstColumn(sql, params)` for generated-key-style first-column extraction.

## Pooling

`ScratchBirdConnectionPool` provides lightweight checkout/release and
`withConnection` helpers for bounded connection reuse.

## Resilience Tuning

Optional DSN parameters:

- `keepalive_interval_ms`
- `keepalive_max_idle_before_check_ms`
- `keepalive_validation_timeout_ms`
- `leak_detection_threshold_ms`
- `leak_detection_check_interval_ms`
- `leak_detection_capture_stack_trace`

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_MANAGER_DSN`
- `SCRATCHBIRD_TEST_BAD_AUTH_DSN` (optional: DSN with intentionally invalid credentials for auth-failure mapping test)

Run all tests:

```bash
swift test
```

Run only env-gated integration coverage:

```bash
swift test --filter IntegrationTests
```

Integration coverage includes direct + manager connect/query, TXN/savepoint,
metadata wrappers, typed error mapping, and resilience timing checks
(single-connection and concurrent multi-connection), plus pool
checkout/release churn assertions.
