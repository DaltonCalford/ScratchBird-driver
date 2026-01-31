# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

**Status:** Active Development (SBWP v1.1 drivers feature-complete for current server capabilities)
**Parent Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages.
These drivers target the ScratchBird native protocol (SBWP v1.1) and provide idiomatic APIs for
each supported language. Emulated protocols (PostgreSQL/MySQL/Firebird) are handled by their
own native client drivers against ScratchBird's emulation listeners.

### Supported Languages (Native SBWP v1.1)

| Language | Directory | Status | Package Manager |
|----------|-----------|--------|-----------------|
| **Go** | `go/` | Development | `go get` |
| **Python** | `python/` | Development | pip/pyproject.toml |
| **Node.js** | `node/` | Development | npm |
| **Ruby** | `ruby/` | Development | gem |
| **Rust** | `rust/` | Development | cargo |
| **PHP** | `php/` | Development | composer |
| **R** | `r/` | Development | CRAN-style |
| **Pascal** | `pascal/` | Development | - |
| **.NET** | `dotnet/` | Development | NuGet |
| **Java/JDBC** | `jdbc/` | Development | Maven/Gradle |

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
- `docs/BUILD_MATRIX.md`

---

## Target Features (SBWP v1.1)

These are the required capabilities for all drivers in this repo:

- **Native Wire Protocol (SBWP v1.1)** - ScratchBird native protocol (port 3092)
- **TLS 1.3 Required** - Encrypted connections without plaintext fallback
- **Server-side Prepare/Bind** - PARSE/BIND/EXECUTE for parameters
- **Transactions** - Always-in-transaction semantics with autocommit mapping
- **Type Mapping** - Full wire type coverage (including composite/geometry/range)

### Current Implementation Notes

- SBWP v1.1 conformance is implemented across all native drivers.
- Binary-only mode is enforced; `binary_transfer=false` is rejected.
- `compression=zstd` is intentionally disabled until server support exists.
- Streaming/paging via `fetch_size` is supported where applicable.
- JDBC/Superset/Metabase metadata uses `sys.*` views with safe fallbacks.

Server-side feature backlog that unlocks optional driver capabilities:
`docs/planning/DRIVER_SERVER_FEATURE_BACKLOG.md`.

### Protocol Scope

These drivers are native-only. For emulated protocol access (PostgreSQL/MySQL/Firebird),
use the standard drivers for those engines against ScratchBird's emulation listeners.

Application-specific drivers (early):
- Superset: `scratchbird-superset-driver/`
- Metabase: `scratchbird-metabase-driver/`

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

### Building All Drivers

Each driver has its own build process. See individual driver READMEs for details.

```bash
# Go
cd go && go build ./...

# Python
cd python && pip install -e .

# Node.js
cd node && npm install && npm run build

# Rust
cd rust && cargo build

# .NET
cd dotnet && dotnet build

# JDBC
cd jdbc && ./gradlew build
```

### Running Tests

```bash
# Go
cd go && go test ./...

# Python
cd python && pytest

# Node.js
cd node && npm test

# Rust
cd rust && cargo test

# .NET
cd dotnet && dotnet test

# JDBC
cd jdbc && ./gradlew test
```

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Requirements

1. Follow the coding style of each language
2. Include tests for new features
3. Update documentation
4. Ensure CI passes before submitting PR

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

**Last Updated:** 2026-01-30
