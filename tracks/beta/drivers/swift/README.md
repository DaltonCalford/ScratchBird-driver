# ScratchBird Swift Driver

Native ScratchBird driver using Swift Concurrency (async/await). SBWP v1.1,
binary-only transport.

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

The current transport uses a direct TCP socket. TLS wiring is pending and
will be added once the Swift TLS/crypto transport is finalized for SBWP.

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
