# ScratchBird Swift Driver

Native ScratchBird driver using Swift Concurrency (async/await). SBWP v1.1,
binary-only transport.

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
