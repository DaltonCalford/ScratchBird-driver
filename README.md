# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

## Project Status

ScratchBird-driver is now in **Initial Early Beta release (`0.1.0`)**.

**Status:** SBWP v1.1 baseline implementation is in place for the released driver set.  
Current verification evidence is captured in `docs/planning/DRIVER_ENTERPRISE_READINESS_*` and
`artifacts/enterprise-readiness/`.

**Parent Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)
**Release Targets:** `docs/planning/RELEASE_TARGETS.md`

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages.
These drivers target the ScratchBird native protocol (SBWP v1.1) and provide idiomatic APIs for
each supported language. Emulated protocols (PostgreSQL/MySQL/Firebird) are handled by their
own native client drivers against ScratchBird's emulation listeners.

### Supported Drivers (Native SBWP v1.1)

| Driver | Directory | Status | Packaging |
|--------|-----------|--------|-----------|
| **C/C++ (libscratchbird_client)** | `tracks/beta/drivers/cpp/` | Initial Early Beta (`0.1.0`) | CMake |
| **ODBC 3.8** | `tracks/alpha/drivers/odbc/` | Initial Early Beta (`0.1.0`) | CMake |
| **Go** | `tracks/alpha/drivers/go/` | Initial Early Beta (`0.1.0`) | `go get` |
| **Python** | `tracks/alpha/drivers/python/` | Initial Early Beta (`0.1.0`) | pip/pyproject.toml |
| **Node.js** | `tracks/alpha/drivers/node/` | Initial Early Beta (`0.1.0`) | npm |
| **Ruby** | `tracks/alpha/drivers/ruby/` | Initial Early Beta (`0.1.0`) | gem |
| **Rust** | `tracks/alpha/drivers/rust/` | Initial Early Beta (`0.1.0`) | cargo |
| **PHP** | `tracks/alpha/drivers/php/` | Initial Early Beta (`0.1.0`) | composer |
| **R** | `tracks/beta/drivers/r/` | Initial Early Beta (`0.1.0`) | CRAN-style |
| **Pascal** | `tracks/alpha/drivers/pascal/` | Initial Early Beta (`0.1.0`) | - |
| **.NET** | `tracks/alpha/drivers/dotnet/` | Initial Early Beta (`0.1.0`) | NuGet |
| **Java/JDBC** | `tracks/alpha/drivers/jdbc/` | Initial Early Beta (`0.1.0`) | Maven/Gradle |
| **Elixir (Ecto)** | `tracks/p3/drivers/elixir/` | In development (post-`0.1.0`) | Hex |
| **Swift (Async/Await)** | `tracks/beta/drivers/swift/` | In development (post-`0.1.0`) | SwiftPM |
| **Dart** | `tracks/beta/drivers/dart/` | In development (post-`0.1.0`) | pub.dev |
| **Mojo** | `tracks/alpha/drivers/mojo/` | In development (post-`0.1.0`) | - |

### Completed Drivers (`0.1.0` Initial Early Beta)

- C/C++ (`tracks/beta/drivers/cpp/`)
- ODBC 3.8 (`tracks/alpha/drivers/odbc/`)
- Go (`tracks/alpha/drivers/go/`)
- Python (`tracks/alpha/drivers/python/`)
- Node.js (`tracks/alpha/drivers/node/`)
- Ruby (`tracks/alpha/drivers/ruby/`)
- Rust (`tracks/alpha/drivers/rust/`)
- PHP (`tracks/alpha/drivers/php/`)
- R (`tracks/beta/drivers/r/`)
- Pascal (`tracks/alpha/drivers/pascal/`)
- .NET (`tracks/alpha/drivers/dotnet/`)
- Java/JDBC (`tracks/alpha/drivers/jdbc/`)

### Future Plans (Currently Unimplemented for `0.1.0`)

- Elixir (Ecto) (`tracks/p3/drivers/elixir/`) - in development
- Swift Async/Await (`tracks/beta/drivers/swift/`) - in development
- Dart (`tracks/beta/drivers/dart/`) - in development
- Mojo (`tracks/alpha/drivers/mojo/`) - in development

### Driver Status Matrix (Snapshot: 2026-02-28)

Build/test snapshot from the latest local verification sweep. This is not a release certification.

| Driver | Build/Test | Notes |
|--------|------------|-------|
| C/C++ | Pass | `cmake --build` (core client tests not run as part of the latest sweep) |
| ODBC | Pass | `cmake --build` (`scratchbird_odbc_tests`) |
| Go | Pass | `go test ./...` |
| Node.js | Pass | `npm install && npm test` (4 integration tests skipped: `SCRATCHBIRD_NODE_URL` not set) |
| Python | Pass | `pytest -q` |
| PHP | Pass | `composer install && ./vendor/bin/phpunit tests` (4 integration tests skipped) |
| Ruby | Pass | `ruby -Ilib:test test/*.rb` |
| Rust | Pass | `cargo test` |
| R | Pass* | `R -q -e ...` (`C` extension tests pass, integration skipped) |
| Pascal | Partial | compile pass; runtime tests are environment-specific |
| .NET | Pass | `dotnet test` |
| Java/JDBC | Pass | `./gradlew test` |
| Elixir | Blocked | `mix test` requires Elixir ~> 1.15 (environment has 1.14) |
| Swift | Pass | `swift test` |
| Dart | Pass | `dart test` |
| Mojo | Blocked | environment has no `mojo` runtime/runner |
| CLI | Pass | core CLI build/test checks; FDW tools gated |

\* R status: in-tree config/type/transport tests pass; integration checks are skipped unless `SCRATCHBIRD_R_URL` is set.

### Current Enterprise Readiness Status

- `DRIVER_ENTERPRISE_READINESS_STRICT_IMPLEMENTATION_MATRIX_2026-02-22.md` defines exact ticket-level completion status and blockers.
- `DRIVER_ENTERPRISE_READINESS_TICKETS_2026-02-22.md` holds ownership and acceptance criteria.
- `DRIVER_ENTERPRISE_READINESS_REMAINING_GAPS_STRICT_2026-02-23.md` contains current unresolved gaps.

Snapshot date for this table is February 28, 2026.

### Cross-Platform CI Coverage

The `Driver CI` workflow validates Windows and Linux for released-driver paths:
- Go, Node.js, Python, Ruby, Rust, PHP, R, .NET, JDBC, Pascal, Dart
- C/C++ client and ODBC driver
- CLI tools on Linux, with Windows build attempt enabled (experimental)

Linux-only CI jobs are used where platform support is not yet available:
- Swift
- Mojo (gated by `MOJO_ENABLED=true`)

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

## Driver Runtime Validation (JDBC + ODBC)

To validate drivers against a live ScratchBird server/parser/listener stack:

```bash
scripts/driver_runtime_stack.sh up
scripts/driver_runtime_stack.sh fixtures
scripts/run_jdbc_odbc_runtime_checks.sh
```

This uses the sibling `../ScratchBird` repository runtime manager and shared
fixtures under `docs/fixtures/`.

---

## Target Features (SBWP v1.1)

These are the required capabilities for all drivers in this repo:

- **Native Wire Protocol (SBWP v1.1)** - ScratchBird native protocol (port 3092)
- **TLS 1.3 Required** - Encrypted connections without plaintext fallback
- **Server-side Prepare/Bind** - PARSE/BIND/EXECUTE for parameters
- **Transactions** - Always-in-transaction semantics with autocommit mapping
- **Type Mapping** - Full wire type coverage (including composite/geometry/range)

### P0 Readiness Checklist (Derived from `docs/planning/RELEASE_TARGETS.md`)

Use this as the minimum bar for `0.1.0` beta completeness; in-development drivers are expected to be below this bar until promoted.

- SBWP v1.1 baseline implemented
- TLS enforced (no plaintext fallback)
- Binary-only parameters enforced
- `compression=zstd` rejected
- Full type matrix encode/decode coverage
- sys.* metadata helpers aligned to the metadata contract
- Conformance harness coverage for baseline protocol and types
- Core server ops viable for testing (create/query/transactions)
- Developer docs/specs prioritized over general docs

### Current Implementation Notes

- Core language drivers implement SBWP v1.1 baseline, but build/test results vary (see Driver Status Matrix). Conformance tracking is in `docs/planning/`.
- Binary-only mode and `compression=zstd` rejection are enforced in core drivers.
- C/C++ client implements SBWP v1.1 framing and SCRAM, with statement-cache helpers wired into the C API.
- Dart/Swift/Elixir are partial and do not yet meet full SBWP conformance requirements (metadata helpers, full type matrix, and conformance tests are incomplete).
- Mojo is currently a Python-bridge adapter (not a native SBWP client).
- Streaming/paging via `fetch_size` is supported where applicable in core drivers.
- ODBC metadata is aligned to sys.* and information_schema; Superset/Metabase still need updates to match finalized sys.columns/sys.index_columns schemas.

Server-side feature backlog that unlocks optional driver capabilities:
`docs/planning/DRIVER_SERVER_FEATURE_BACKLOG.md`.

### Protocol Scope

These drivers are native-only. For emulated protocol access (PostgreSQL/MySQL/Firebird),
use the standard drivers for those engines against ScratchBird's emulation listeners.

Application-specific drivers:
- Superset: `tracks/beta/integrations/scratchbird-superset-driver/`
- Metabase: `tracks/alpha/integrations/scratchbird-metabase-driver/`

Integration templates for ecosystem targets live in:
`docs/specifications/integrations/` (drivers, ORMs, tools, apps, cloud).

### Integration Targets (Templates)

The integrations catalog includes templates for the full ecosystem scope:

- **ORMs & Frameworks:** SQLAlchemy, Sequelize, Hibernate/JPA, Entity Framework Core, TypeORM, Prisma, Rails ActiveRecord, Laravel Eloquent, Dapper, Django ORM, Cypher/OpenCypher, Gremlin/TinkerPop
- **Big Data & Streaming:** Apache Spark, Apache Flink, Apache Kafka, Hadoop (Hive/Pig/HBase), Talend, Pentaho, Informatica
- **Database Tools:** DBeaver, pgAdmin, MySQL Workbench, DataGrip, Tableau, Power BI, Qlik, Grafana, Metabase, Prometheus, Excel (ODBC)
- **Applications:** WordPress, Drupal, Joomla, Magento, WooCommerce, QGIS, GeoServer, Mattermost, Odoo
- **Cloud & Container:** Docker, Kubernetes, Terraform, AWS, GCP, Azure

### CLI Tools

| Tool | Purpose | Status |
|------|---------|--------|
| **sb_isql** | Native ScratchBird interactive shell | Implemented (baseline) |
| **sb_fb_isql** | Firebird protocol script runner | Gated (requires FDW adapters from engine repo + `SB_BUILD_CLI_FDW=ON`) |
| **sb_pg_isql** | PostgreSQL protocol script runner | Gated (requires FDW adapters from engine repo + `SB_BUILD_CLI_FDW=ON`) |
| **sb_my_isql** | MySQL protocol script runner | Gated (requires FDW adapters from engine repo + `SB_BUILD_CLI_FDW=ON`) |
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

**Last Updated:** 2026-02-18
