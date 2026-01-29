# ScratchBird R Driver

R DBI-compatible driver for ScratchBird using the ScratchBird wire protocol.

## Documentation

- Getting started: `docs/getting-started/r.md`
- API reference: `docs/api-reference/r.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

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
