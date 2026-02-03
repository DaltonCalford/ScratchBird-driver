[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# R Driver Guide

**Status:** Implemented (SBWP v1.1 baseline)
**Last Updated:** 2026-02-02

---

## Overview

R DBI-compatible driver for ScratchBird using SBWP v1.1.

## Install

```r
# From this repo
# Install the package after building the source
```

## Quick Start

```r
library(DBI)
library(scratchbird)

con <- dbConnect(Scratchbird(), "scratchbird://user:pass@localhost:3092/mydb")
df <- dbGetQuery(con, "SELECT 1")
dbDisconnect(con)
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/r.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/r.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/r/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_R_URL`.

