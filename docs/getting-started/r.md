# R Driver

## Install

From the repo:

```r
# Run from the repo root
install.packages("r", repos = NULL, type = "source")
```

## Quick Start

```r
library(DBI)
library(scratchbird)

con <- dbConnect(Scratchbird(), "scratchbird://user:pass@localhost:3092/mydb")
res <- dbGetQuery(con, "SELECT 1")
dbDisconnect(con)
```

## Connection Strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_R_URL`
