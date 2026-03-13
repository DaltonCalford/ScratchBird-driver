# Swift Driver

## Status

Partial SBWP v1.1 implementation. TLS required, binary-only enforced, zstd rejected; metadata helpers and conformance coverage remain incomplete.

## Build

```bash
cd tracks/p3/drivers/swift
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

## Tests

Integration tests use:

- `SCRATCHBIRD_TEST_DSN`
