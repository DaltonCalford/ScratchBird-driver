# ScratchBird Driver Documentation

This directory contains the user-facing and implementation-facing
documentation for the ScratchBird drivers.

Current repo state:

- baseline-complete lanes remain the primary Beta 1 ready surface
- partial lanes and adapters have explicit outstanding-gap documentation
- ten newly promoted Beta 1 expansion lanes now have benchmark research,
  lane-local gap reports, implementation-ready specs, and later
  server-verification packets, but still await implementation

For day-to-day driver use, start with:

- [Getting Started](getting-started/README.md)
- [API Reference](api-reference/README.md)
- [User Documentation](user-documentation/README.md)
- [Reference Packets](reference/README.md)
- [Connection Modes and Auth](user-documentation/connectivity/connection-modes-and-auth.md)
- [MGA Reconnect And Transaction Recovery Audit](audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md)

Planning and specification documents remain in this tree for engineering work,
but the driver guides in `getting-started/`, `api-reference/`, and the lane
READMEs are the primary sources for install and usage guidance.

## Structure

| Directory | Description |
|-----------|-------------|
| **getting-started/** | Installation and quick start guides for each driver |
| **api-reference/** | API documentation for each language driver |
| **development/** | Development guides, testing, and contribution information |
| **reference/** | Benchmark research packets and implementation anchors |
| **specifications/** | Wire protocol and driver specifications |
| **audit/** | Implementation audits and gap analysis |
| **planning/** | Remediation plans and implementation checklists |
| **fixtures/** | Shared SQL fixtures for conformance tests |
| **user-documentation/** | CLI tool and connectivity guides |

## Driver Documentation

Each driver has two documentation layers:

- Per-driver guides in `docs/getting-started/` and `docs/api-reference/`
- Language READMEs in the driver directories

- [Go Driver](../tracks/p3/drivers/go/README.md)
- [Python Driver](../tracks/p3/drivers/python/README.md)
- [Node.js Driver](../tracks/p3/drivers/node/README.md)
- [Ruby Driver](../tracks/p3/drivers/ruby/README.md)
- [Rust Driver](../tracks/p3/drivers/rust/README.md)
- [PHP Driver](../tracks/p3/drivers/php/README.md)
- [R Driver](../tracks/p3/drivers/r/README.md)
- [Pascal Driver](../tracks/p3/drivers/pascal/README.md)
- [.NET Driver](../tracks/p3/drivers/dotnet/README.md)
- [JDBC Driver](../tracks/p3/drivers/jdbc/README.md)
- [C/C++ Client](../tracks/p3/drivers/cpp/README.md)
- [ODBC Driver](../tracks/p3/drivers/odbc/README.md)
- [CLI Tools](../tracks/p3/drivers/cli/README.md)
- [Superset Driver](../tracks/beta/integrations/scratchbird-superset-driver/README.md)
- [Metabase Driver](../tracks/alpha/integrations/scratchbird-metabase-driver/README.md)
- [DBeaver Integration](../tracks/alpha/integrations/scratchbird-dbeaver-driver/README.md)
- [Elixir (Ecto) Driver](../tracks/p3/drivers/elixir/README.md)
- [Swift Async Driver](../tracks/p3/drivers/swift/README.md)
- [Dart Driver](../tracks/p3/drivers/dart/README.md)
- [Mojo Driver](../tracks/p3/drivers/mojo/README.md)

Quick links:

- [Getting Started Index](getting-started/README.md)
- [API Reference Index](api-reference/README.md)
- [Reference Packet Index](reference/README.md)
- [CLI Tools](user-documentation/tools/README.md)
- [User Documentation](user-documentation/README.md)
- [Development Guides](development/README.md)

## Quick Links

- [Main ScratchBird Project](https://github.com/DaltonCalford/ScratchBird)
- [Native Protocol Alignment](specifications/NATIVE_PROTOCOL_ALIGNMENT.md)
- [Driver Audit](audit/DRIVER_IMPLEMENTATION_AUDIT.md)
- [Expansion Remaining Work](audit/DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_REMAINING_WORK.md)
- [MGA Reconnect / Transaction Recovery Audit](audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md)
- [Driver Remediation Plan](planning/DRIVER_REMEDIATION_PLAN.md)
- [Contributing Guide](../CONTRIBUTING.md)
