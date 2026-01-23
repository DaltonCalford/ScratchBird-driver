# Go Driver

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

func main() {
    db, err := sql.Open("scratchbird", "scratchbird://user:pass@localhost:3092/mydb")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    var one int
    if err := db.QueryRow("SELECT 1").Scan(&one); err != nil {
        panic(err)
    }
}
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

## Prepare/Bind

Use database/sql prepared statements so parameters are bound server-side:

```go
stmt, err := db.Prepare("SELECT ?::INTEGER")
if err != nil {
    panic(err)
}
row := stmt.QueryRow(42)
```

## Tests

Integration and conformance tests are gated by environment variables:

- `SCRATCHBIRD_GO_URL`
- `SCRATCHBIRD_CONFORMANCE_MANIFEST`
