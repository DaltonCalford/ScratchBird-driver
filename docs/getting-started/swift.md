# Swift Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `partial`
- Best-in-class benchmark: `PostgresNIO`
- Authoritative lane spec: `docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/swift.md`
- Remaining gap summary: Cancellation timing, portal suspend/resume, richer metadata families, advanced type roundtrips, error propagation, and pool recovery semantics remain incomplete.
<!-- lane-status:end -->

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
