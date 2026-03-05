# R Driver

## Install

From the repo:

```r
# Run from the repo root
install.packages("tracks/beta/drivers/r", repos = NULL, type = "source")
```

Dependencies:

- `DBI`
- `openssl`

```r
install.packages(c("DBI", "openssl"))
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

Manager-proxy URI:

```
scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_R_URL`
- `SCRATCHBIRD_R_MANAGER_URL`
- `SCRATCHBIRD_R_CANCEL_SQL`
