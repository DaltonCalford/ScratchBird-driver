# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

**Status:** Development / Test Platform
**Parent Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages. These drivers implement the ScratchBird wire protocol and provide idiomatic APIs for each supported language.

### Supported Languages

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

- Running ScratchBird server (default ports: Native 3092, PostgreSQL 5432, MySQL 3306, Firebird 3050)
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

---

## Features

All drivers implement:

- **Native Wire Protocol** - ScratchBird native protocol (port 3092)
- **Connection Pooling** - Built-in connection pool support
- **TLS/SSL** - Encrypted connections
- **Authentication** - SCRAM-SHA-256, password, certificate authentication
- **Prepared Statements** - Parameterized queries
- **Transactions** - Full ACID transaction support
- **Type Mapping** - Native type conversion for each language

### Wire Protocol Compatibility

Drivers connect to ScratchBird's native protocol by default. ScratchBird also supports:
- PostgreSQL protocol (port 5432)
- MySQL protocol (port 3306)
- Firebird protocol (port 3050)

For legacy protocol support, use the respective language's standard drivers with ScratchBird's emulation layer.

---

## Project Structure

```
ScratchBird-driver/
├── docs/                   Documentation
│   ├── getting-started/    Installation & quick start guides
│   ├── api-reference/      API documentation
│   ├── development/        Development guides
│   └── specifications/     Wire protocol specs
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
- **[Wire Protocol](docs/specifications/)** - Protocol specifications

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

**Last Updated:** January 2026
