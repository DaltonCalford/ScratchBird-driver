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

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
