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

- [Go Driver](../go/README.md)
- [Python Driver](../python/README.md)
- [Node.js Driver](../node/README.md)
- [Ruby Driver](../ruby/README.md)
- [Rust Driver](../rust/README.md)
- [PHP Driver](../php/README.md)
- [R Driver](../r/README.md)
- [Pascal Driver](../pascal/README.md)
- [.NET Driver](../dotnet/) - See solution file
- [JDBC Driver](../jdbc/) - Java/Gradle project
- [C/C++ Client](../cpp/) - CMake-based client library
- [ODBC Driver](../odbc/) - ODBC 3.8 driver (CMake)
- [Superset Driver](../scratchbird-superset-driver/README.md)
- [Metabase Driver](../scratchbird-metabase-driver/README.md)
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
