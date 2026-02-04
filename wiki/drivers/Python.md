[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Python Driver Guide

**Status:** Alpha track (SBWP v1.1 baseline)
**Last Updated:** 2026-02-04

---

## Overview

ScratchBird DB-API 2.0 driver using SBWP v1.1.

## Install

```bash
pip install scratchbird
```

## Quick Start

```python
import scratchbird

conn = scratchbird.connect("scratchbird://user:pass@localhost:3092/mydb")
cur = conn.cursor()
cur.execute("SELECT 1")
print(cur.fetchone())
cur.close()
conn.close()
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/python.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/python.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/alpha/drivers/python/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_TEST_DSN`.

