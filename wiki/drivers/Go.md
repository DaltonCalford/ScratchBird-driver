[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Go Driver Guide

**Status:** Alpha track (SBWP v1.1 baseline)
**Last Updated:** 2026-02-04

---

## Overview

ScratchBird native SBWP v1.1 driver for Go (`database/sql`).

## Install

```bash
go get github.com/scratchbird/scratchbird-go
```

## Quick Start

```go
import (
    "database/sql"
    _ "github.com/scratchbird/scratchbird-go"
)

db, err := sql.Open("scratchbird", "scratchbird://user:pass@localhost:3092/mydb")
if err != nil {
    panic(err)
}
defer db.Close()
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/go.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/go.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/alpha/drivers/go/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_GO_URL` and `SCRATCHBIRD_CONFORMANCE_MANIFEST`.

