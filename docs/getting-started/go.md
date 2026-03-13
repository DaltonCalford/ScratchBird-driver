# Go Driver

## Install

The module path is `github.com/scratchbird/scratchbird-go`.

For repo-local development:

```bash
cd tracks/p3/drivers/go
go test ./...
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

Direct/native:

```
scratchbird://user:password@host:3092/database?sslmode=prefer
```

Manager-proxy:

```
scratchbird://user:password@host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current lane behavior:

- Direct DSNs accept the standard `sslmode` values, including `disable`.
- Compatibility startup keys include `binary_transfer=false` and
  `compression=zstd|none|off`.
- Manager-proxy and auth-plugin startup keys are supported:
  `client_flags|connect_client_flags`, `auth_method_payload`,
  `auth_required_methods`, `auth_forbidden_methods`,
  `auth_require_channel_binding`, `workload_identity_token`, and
  `proxy_principal_assertion`.

## Prepare/Bind

Use `database/sql` prepared statements so parameters are bound server-side:

```go
stmt, err := db.Prepare("SELECT ?::INTEGER")
if err != nil {
    panic(err)
}
row := stmt.QueryRow(42)
_ = row
```

## Tests

Integration and conformance tests are gated by environment variables:

- `SCRATCHBIRD_GO_URL`
- `SCRATCHBIRD_CONFORMANCE_MANIFEST`
