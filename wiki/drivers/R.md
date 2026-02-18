[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# R Driver Guide

**Status:** Initial Early Beta (`0.1.0`) (SBWP v1.1 baseline)
**Last Updated:** 2026-02-18

---

## Overview

R DBI-compatible driver for ScratchBird using SBWP v1.1.

## Install

```r
# From the repo root
install.packages("tracks/beta/drivers/r", repos = NULL, type = "source")
```

Dependencies: `DBI`, `openssl` (tests: `testthat`).

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
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/beta/drivers/r/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_R_URL`.
