# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

**Status:** In-progress conformance. Core language drivers are SBWP v1.1 baseline; Dart/Swift/Elixir/Mojo remain partial. C++ type coverage expanded with initial conformance tests.
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
| **C/C++ (libscratchbird_client)** | `tracks/beta/drivers/cpp/` | SBWP core; type coverage expanded (initial conformance tests) | CMake |
| **ODBC 3.8** | `tracks/alpha/drivers/odbc/` | SBWP v1.1 baseline (metadata aligned) | CMake |
| **Go** | `tracks/alpha/drivers/go/` | Implemented (SBWP v1.1 baseline) | `go get` |
| **Python** | `tracks/alpha/drivers/python/` | Implemented (SBWP v1.1 baseline) | pip/pyproject.toml |
| **Node.js** | `tracks/alpha/drivers/node/` | Implemented (SBWP v1.1 baseline) | npm |
| **Ruby** | `tracks/alpha/drivers/ruby/` | Implemented (SBWP v1.1 baseline) | gem |
| **Rust** | `tracks/alpha/drivers/rust/` | Implemented (SBWP v1.1 baseline) | cargo |
| **PHP** | `tracks/alpha/drivers/php/` | Implemented (SBWP v1.1 baseline) | composer |
| **R** | `tracks/beta/drivers/r/` | Implemented (SBWP v1.1 baseline) | CRAN-style |
| **Pascal** | `tracks/alpha/drivers/pascal/` | Implemented (SBWP v1.1 baseline) | - |
| **.NET** | `tracks/alpha/drivers/dotnet/` | Implemented (SBWP v1.1 baseline) | NuGet |
| **Java/JDBC** | `tracks/alpha/drivers/jdbc/` | Implemented (SBWP v1.1 baseline) | Maven/Gradle |
| **Elixir (Ecto)** | `tracks/p3/drivers/elixir/` | Partial (TLS required, type coverage expanded, initial tests) | Hex |
| **Swift (Async/Await)** | `tracks/beta/drivers/swift/` | Partial (TLS required, type coverage expanded, initial tests) | SwiftPM |
| **Dart** | `tracks/beta/drivers/dart/` | Partial (TLS required, type coverage expanded, initial tests) | pub.dev |
| **Mojo** | `tracks/alpha/drivers/mojo/` | Partial (native SBWP transport; type coverage incomplete) | - |

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
- `docs/BUILD_MATRIX.md` (required tools + build/test matrix, Ubuntu 24.04 quick-install)

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
- C++ type matrix coverage is expanded; initial conformance tests added.
- Dart/Swift/Elixir type coverage expanded (arrays/composite/range/vector/inet/cidr/macaddr) and metadata helpers added; initial conformance tests added.
- Streaming/paging via `fetch_size` is supported where applicable in core drivers.
- ODBC metadata is aligned to sys.* and information_schema; Superset/Metabase still need updates to match finalized sys.columns/sys.index_columns schemas.

Server-side feature backlog that unlocks optional driver capabilities:
`docs/planning/DRIVER_SERVER_FEATURE_BACKLOG.md`.

### Protocol Scope

These drivers are native-only. For emulated protocol access (PostgreSQL/MySQL/Firebird),
use the standard drivers for those engines against ScratchBird's emulation listeners.

Application-specific drivers (early):
- Superset: `tracks/beta/integrations/scratchbird-superset-driver/`
- Metabase: `tracks/alpha/integrations/scratchbird-metabase-driver/`

Integration templates (Alpha/Beta ecosystem targets) live in:
`docs/specifications/integrations/` (drivers, ORMs, tools, apps, cloud).

### Integration Targets (Templates)

The integrations catalog includes templates for the full ecosystem scope:

- **ORMs & Frameworks:** SQLAlchemy, Sequelize, Hibernate/JPA, Entity Framework Core, TypeORM, Prisma, Rails ActiveRecord, Laravel Eloquent, Dapper, Django ORM, Cypher/OpenCypher, Gremlin/TinkerPop
- **Big Data & Streaming:** Apache Spark, Apache Flink, Apache Kafka, Hadoop (Hive/Pig/HBase), Talend, Pentaho, Informatica
- **AI/ML:** Vector APIs, LangChain, Haystack
- **Database Tools:** DBeaver, pgAdmin, MySQL Workbench, DataGrip, Tableau, Power BI, Qlik, Grafana, Metabase, Prometheus, Excel (ODBC)
- **Applications:** WordPress, Drupal, Joomla, Magento, WooCommerce, QGIS, GeoServer, Mattermost, Odoo
- **Cloud & Container:** Docker, Kubernetes, Terraform, AWS, GCP, Azure

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

### Mojo Conformance Quick Run

Use the Make/Just targets to run the Mojo conformance adapter with the default
manifest:

```bash
make mojo-conformance
```

```bash
just mojo-conformance
```

Set `SCRATCHBIRD_MOJO_URL` to point at a running server to execute `query`
tests. Prepare/bind and cancel are gated by `SCRATCHBIRD_MOJO_ENABLE_PREPARE_BIND`
and `SCRATCHBIRD_MOJO_ENABLE_CANCEL` when those features land.

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
│   └── specifications/     Protocol and driver specs (plus integration templates)
├── wiki/                   GitHub wiki pages (source)
├── tracks/alpha/drivers/cli/                    CLI tools (native + emulated protocol runners)
├── tracks/beta/drivers/cpp/                    C/C++ client library (SBWP)
├── tracks/alpha/drivers/odbc/                   ODBC 3.8 driver (SBWP)
├── tracks/alpha/drivers/go/                     Go driver
├── tracks/alpha/drivers/python/                 Python driver
├── tracks/alpha/drivers/node/                   Node.js driver
├── tracks/alpha/drivers/ruby/                   Ruby driver
├── tracks/alpha/drivers/rust/                   Rust driver
├── tracks/alpha/drivers/php/                    PHP driver
├── tracks/beta/drivers/r/                      R driver
├── tracks/alpha/drivers/pascal/                 Pascal driver
├── tracks/alpha/drivers/dotnet/                 .NET driver
├── tracks/alpha/drivers/jdbc/                   JDBC driver (Java)
├── tracks/beta/drivers/dart/                   Dart driver
├── tracks/beta/drivers/swift/                  Swift driver
├── tracks/p3/drivers/elixir/                 Elixir Ecto adapter
├── tracks/alpha/drivers/mojo/                   Mojo adapter
├── tracks/beta/integrations/scratchbird-superset-driver/   Superset dialect
├── tracks/alpha/integrations/scratchbird-metabase-driver/   Metabase driver
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
