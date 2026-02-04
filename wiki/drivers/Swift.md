[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Swift Driver Guide

**Status:** Beta track (SBWP v1.1 baseline)
**Last Updated:** 2026-02-04

---

## Overview

Native ScratchBird driver using Swift Concurrency (async/await).

## Install

```bash
cd tracks/beta/drivers/swift
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
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/beta/drivers/swift/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN`.
