# ScratchBird Go Driver

ScratchBird native wire protocol driver for Go (`database/sql`).

## Documentation

- Getting started: `docs/getting-started/go.md`
- API reference: `docs/api-reference/go.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Usage

```go
import (
    "database/sql"
    _ "github.com/scratchbird/scratchbird-go"
)

db, err := sql.Open("scratchbird", "scratchbird://user:pass@localhost:3092/db")
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

## Conformance testing

Set the following environment variables to run the manifest-driven conformance test:

- `SCRATCHBIRD_GO_URL` - ScratchBird DSN/URL for the Go driver
- `SCRATCHBIRD_CONFORMANCE_MANIFEST` - Path to the manifest JSON (e.g., `docs/fixtures/sbwp_conformance_manifest.json`)
