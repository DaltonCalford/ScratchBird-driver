# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

**Status:** In-progress conformance. Core language drivers are SBWP v1.1 baseline; Dart/Swift/Elixir/Mojo and C++ type coverage remain partial.
**Parent Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages.
These drivers target the ScratchBird native protocol (SBWP v1.1) and provide idiomatic APIs for
each supported language. Emulated protocols (PostgreSQL/MySQL/Firebird) are handled by their
own native client drivers against ScratchBird's emulation listeners.

### Supported Drivers (Native SBWP v1.1)

| Driver | Directory | Status | Packaging |
|--------|-----------|--------|-----------|
| **C/C++ (libscratchbird_client)** | `cpp/` | SBWP core; type coverage partial | CMake |
| **ODBC 3.8** | `odbc/` | SBWP v1.1 baseline (metadata aligned) | CMake |
| **Go** | `go/` | Implemented (SBWP v1.1 baseline) | `go get` |
| **Python** | `python/` | Implemented (SBWP v1.1 baseline) | pip/pyproject.toml |
| **Node.js** | `node/` | Implemented (SBWP v1.1 baseline) | npm |
| **Ruby** | `ruby/` | Implemented (SBWP v1.1 baseline) | gem |
| **Rust** | `rust/` | Implemented (SBWP v1.1 baseline) | cargo |
| **PHP** | `php/` | Implemented (SBWP v1.1 baseline) | composer |
| **R** | `r/` | Implemented (SBWP v1.1 baseline) | CRAN-style |
| **Pascal** | `pascal/` | Implemented (SBWP v1.1 baseline) | - |
| **.NET** | `dotnet/` | Implemented (SBWP v1.1 baseline) | NuGet |
| **Java/JDBC** | `jdbc/` | Implemented (SBWP v1.1 baseline) | Maven/Gradle |
| **Elixir (Ecto)** | `elixir/` | Partial (TLS required, type coverage incomplete) | Hex |
| **Swift (Async/Await)** | `swift/` | Partial (TLS required, type coverage incomplete) | SwiftPM |
| **Dart** | `dart/` | Partial (TLS required, type coverage incomplete) | pub.dev |
| **Mojo** | `mojo/` | Bridge (TLS required, type coverage incomplete) | - |

---

## Quick Start

### Prerequisites

- Running ScratchBird server (native listener on port 3092)
- Language-specific toolchain installed

### Go

```go
import "github.com/DaltonCalford/ScratchBird-driver/go"

db, err := scratchbird.Open("scratchbird://localhost:3092/mydb")
if err != nil {
    log.Fatal(err)
}
defer db.Close()

rows, err := db.Query("SELECT * FROM users")
```

### Python

```python
import scratchbird

conn = scratchbird.connect(
    host="localhost",
    port=3092,
    database="mydb"
)

cursor = conn.cursor()
cursor.execute("SELECT * FROM users")
```

### Node.js

```javascript
const { Client } = require('scratchbird');

const client = new Client({
    host: 'localhost',
    port: 3092,
    database: 'mydb'
});

await client.connect();
const result = await client.query('SELECT * FROM users');
```

### Rust

```rust
use scratchbird::Client;

let client = Client::connect("scratchbird://localhost:3092/mydb").await?;
let rows = client.query("SELECT * FROM users", &[]).await?;
```

See individual driver directories for complete documentation and examples.

## Build Matrix (Windows/Linux)

Cross-platform build and test commands are captured in:
- `docs/BUILD_MATRIX.md` (required tools + build/test matrix)

---

## Target Features (SBWP v1.1)

These are the required capabilities for all drivers in this repo:

- **Native Wire Protocol (SBWP v1.1)** - ScratchBird native protocol (port 3092)
- **TLS 1.3 Required** - Encrypted connections without plaintext fallback
- **Server-side Prepare/Bind** - PARSE/BIND/EXECUTE for parameters
- **Transactions** - Always-in-transaction semantics with autocommit mapping
- **Type Mapping** - Full wire type coverage (including composite/geometry/range)

### Current Implementation Notes

- Core language drivers (Go/Node/Python/Ruby/Rust/PHP/R/Pascal/.NET/JDBC/ODBC) implement SBWP v1.1 baseline; conformance is tracked in `docs/planning/`.
- Binary-only mode and `compression=zstd` rejection are enforced in core drivers and Dart/Swift/Elixir/Mojo.
- Streaming/paging via `fetch_size` is supported where applicable in core drivers.
- ODBC metadata is aligned to sys.* and information_schema; Superset/Metabase still need updates to match finalized sys.columns/sys.index_columns schemas.

Server-side feature backlog that unlocks optional driver capabilities:
`docs/planning/DRIVER_SERVER_FEATURE_BACKLOG.md`.

### Protocol Scope

These drivers are native-only. For emulated protocol access (PostgreSQL/MySQL/Firebird),
use the standard drivers for those engines against ScratchBird's emulation listeners.

Application-specific drivers (early):
- Superset: `scratchbird-superset-driver/`
- Metabase: `scratchbird-metabase-driver/`

### CLI Tools

| Tool | Purpose | Status |
|------|---------|--------|
| **sb_isql** | Native ScratchBird interactive shell | Implemented (baseline) |
| **sb_fb_isql** | Firebird protocol script runner | Implemented (baseline) |
| **sb_pg_isql** | PostgreSQL protocol script runner | Implemented (baseline) |
| **sb_my_isql** | MySQL protocol script runner | Implemented (baseline) |
| **sb_admin** | Server administration CLI | Implemented (baseline) |
| **sb_backup** | Backup/restore CLI | Implemented (baseline) |
| **sb_security** | User/role management CLI | Implemented (baseline) |
| **sb_verify** | Database verification CLI | Implemented (baseline) |
| **sbdriver-conformance** | SBWP conformance adapter | Implemented (baseline) |

---

## Project Structure

```
ScratchBird-driver/
├── docs/                   Documentation
│   ├── getting-started/    Installation & quick start guides
│   ├── api-reference/      API documentation
│   ├── development/        Development guides
│   └── specifications/     Wire protocol specs
│   ├── audit/              Audit reports and gap analysis
│   └── planning/           Remediation plans
├── wiki/                   GitHub wiki pages (source)
├── cli/                    CLI tools (native + emulated protocol runners)
├── cpp/                    C/C++ client library (SBWP)
├── odbc/                   ODBC 3.8 driver (SBWP)
├── go/                     Go driver
├── python/                 Python driver
├── node/                   Node.js driver
├── ruby/                   Ruby driver
├── rust/                   Rust driver
├── php/                    PHP driver
├── r/                      R driver
├── pascal/                 Pascal driver
├── dotnet/                 .NET driver
├── jdbc/                   JDBC driver (Java)
├── dart/                   Dart driver
├── swift/                  Swift driver
├── elixir/                 Elixir Ecto adapter
├── mojo/                   Mojo adapter
├── scratchbird-superset-driver/   Superset dialect
├── scratchbird-metabase-driver/   Metabase driver
├── CONTRIBUTING.md         Contribution guidelines
├── CHANGELOG.md            Version history
└── LICENSE                 IDPL License
```

---

## Documentation

- **[Documentation Index](docs/README.md)** - Full documentation overview
- **[Getting Started](docs/getting-started/)** - Installation and setup guides
- **[API Reference](docs/api-reference/)** - Detailed API documentation
- **[Specifications](docs/specifications/)** - Protocol and driver specs
- **[Wiki Source](wiki/)** - GitHub wiki pages (ready to sync)

---

## Development

- **[Development notes](docs/development/development-notes.md)** - Build workflows and contributor expectations
- **[Build and test matrix](docs/development/build-and-test.md)** - Per-driver build/test commands and env vars
- **[Development index](docs/development/README.md)** - Full development documentation list

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Related Projects

- **[ScratchBird](https://github.com/DaltonCalford/ScratchBird)** - The ScratchBird database engine
- **Firebird** - MGA architecture inspiration

---

## License

This project is licensed under the Initial Developer's Public License (IDPL).
See [LICENSE](LICENSE) for details.

---

## Support

- **Issues:** [GitHub Issues](https://github.com/DaltonCalford/ScratchBird-driver/issues)
- **Main Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)

---

**Last Updated:** 2026-02-04
