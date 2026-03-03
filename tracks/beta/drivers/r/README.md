# ScratchBird R Driver

R DBI-compatible driver for ScratchBird using the ScratchBird wire protocol.

## Documentation

- Lane baseline requirement mapping (S0): [BASELINE_REQUIREMENT_MAPPING.md](BASELINE_REQUIREMENT_MAPPING.md)
- Getting started: `docs/getting-started/r.md`
- API reference: `docs/api-reference/r.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

Dependencies: `DBI`, `openssl` (tests: `testthat`).

## Usage

```r
library(DBI)
library(scratchbird)

con <- dbConnect(Scratchbird(), "scratchbird://user:pass@localhost:3092/mydb")
df <- dbGetQuery(con, "SELECT 1")
dbDisconnect(con)
```

## Connection strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```
