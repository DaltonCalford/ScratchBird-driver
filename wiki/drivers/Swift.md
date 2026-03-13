[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Swift Driver Guide

**Status:** In development (post-`0.1.0`) (partial SBWP v1.1; TLS required; binary-only enforced; zstd rejected)
**Last Updated:** 2026-02-18

---

## Overview

Native ScratchBird driver using Swift Concurrency (async/await), partial SBWP support.

## Install

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

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/swift.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/swift.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/p3/drivers/swift/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN`.
