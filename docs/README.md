# ScratchBird Driver Documentation

This directory contains documentation for the ScratchBird database drivers.

## Structure

| Directory | Description |
|-----------|-------------|
| **getting-started/** | Installation and quick start guides for each driver |
| **api-reference/** | API documentation for each language driver |
| **development/** | Development guides, testing, and contribution information |
| **specifications/** | Wire protocol and driver specifications |
| **audit/** | Implementation audits and gap analysis |
| **planning/** | Remediation plans and implementation checklists |
| **fixtures/** | Shared SQL fixtures for conformance tests |
| **user-documentation/** | CLI tool and connectivity guides |

## Driver Documentation

Each driver has two documentation layers:

- Per-driver guides in `docs/getting-started/` and `docs/api-reference/`
- Language READMEs in the driver directories

- [Go Driver](../tracks/alpha/drivers/go/README.md)
- [Python Driver](../tracks/alpha/drivers/python/README.md)
- [Node.js Driver](../tracks/alpha/drivers/node/README.md)
- [Ruby Driver](../tracks/alpha/drivers/ruby/README.md)
- [Rust Driver](../tracks/alpha/drivers/rust/README.md)
- [PHP Driver](../tracks/alpha/drivers/php/README.md)
- [R Driver](../tracks/beta/drivers/r/README.md)
- [Pascal Driver](../tracks/alpha/drivers/pascal/README.md)
- [.NET Driver](../tracks/alpha/drivers/dotnet/) - See solution file
- [JDBC Driver](../tracks/alpha/drivers/jdbc/) - Java/Gradle project
- [C/C++ Client](../tracks/beta/drivers/cpp/) - CMake-based client library
- [ODBC Driver](../tracks/alpha/drivers/odbc/) - ODBC 3.8 driver (CMake)
- [Superset Driver](../tracks/beta/integrations/scratchbird-superset-driver/README.md)
- [Metabase Driver](../tracks/alpha/integrations/scratchbird-metabase-driver/README.md)
- [Elixir (Ecto) Driver (planned)](specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md)
- [Swift Async Driver (planned)](specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md)
- [Dart Driver (planned)](specifications/DRIVER_DART_DATABASE_API.md)
- [Mojo Driver (planned)](specifications/DRIVER_MOJO_NATIVE_API.md)

Quick links:

- [Getting Started Index](getting-started/README.md)
- [API Reference Index](api-reference/README.md)
- [CLI Tools](user-documentation/tools/README.md)
- [User Documentation](user-documentation/README.md)
- [Development Guides](development/README.md)

## Quick Links

- [Main ScratchBird Project](https://github.com/DaltonCalford/ScratchBird)
- [Native Protocol Alignment](specifications/NATIVE_PROTOCOL_ALIGNMENT.md)
- [Driver Audit](audit/DRIVER_IMPLEMENTATION_AUDIT.md)
- [Driver Remediation Plan](planning/DRIVER_REMEDIATION_PLAN.md)
- [Contributing Guide](../CONTRIBUTING.md)
