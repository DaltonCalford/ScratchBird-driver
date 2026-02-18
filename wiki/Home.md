# ScratchBird Drivers Wiki

Official native drivers for the ScratchBird database engine. Released drivers target ScratchBird Wire Protocol (SBWP v1.1) and the native parser execution boundary.

## Project Status

ScratchBird-driver is in **Initial Early Beta release (`0.1.0`)**.

**Status:** Completed drivers are promoted to `0.1.0` beta. Incomplete drivers (Elixir/Swift/Dart/Mojo) remain in active development for post-`0.1.0`.

Build/Test snapshot (2026-02-07): Go/Node/Python/Ruby/Rust/PHP/.NET/Swift pass (integration gated by env vars). C/C++/ODBC/CLI builds pass (OpenSSL/GTest/ODBC header warnings). JDBC build passes with JDK 17. Pascal compiles but TLS 1.3 is unavailable in Indy 10. R `R CMD check` completes with warnings (missing documentation entries, replacement function arg name, generic/method consistency). Elixir tests require Elixir 1.15. Dart/Mojo toolchains not installed. FDW CLI tools remain gated. See `Drivers` and `docs/BUILD_MATRIX.md` for full details.

## Overview

This repository contains native SBWP drivers, C/ODBC tooling, and CLI utilities for ScratchBird. Each driver targets the native wire protocol for direct connections to ScratchBird on port 3092.

## Wiki Contents

- [Getting Started](Getting-Started) - Connection strings, DSN formats, quick examples
- [Drivers](Drivers) - Per-language installation and usage
- [Protocol and Specs](Protocol-and-Specs) - Wire protocol details and type mappings
- [Conformance Testing](Conformance-Testing) - Shared test harness for protocol compliance
- [Development](Development) - Build commands, testing, and release packaging
- [Metabase Driver](Metabase-Driver) - Metabase plugin installation
- [Superset Driver](Superset-Driver) - Apache Superset dialect

## Supported Drivers

| Driver | Package/Module | Status |
|--------|----------------|--------|
| C/C++ | libscratchbird_client | Initial Early Beta (`0.1.0`) |
| ODBC 3.8 | scratchbird_odbc | Initial Early Beta (`0.1.0`) |
| Go | scratchbird-go | Initial Early Beta (`0.1.0`) |
| Python | scratchbird | Initial Early Beta (`0.1.0`) |
| Node.js | scratchbird | Initial Early Beta (`0.1.0`) |
| Ruby | scratchbird | Initial Early Beta (`0.1.0`) |
| Rust | scratchbird | Initial Early Beta (`0.1.0`) |
| PHP | scratchbird | Initial Early Beta (`0.1.0`) |
| R | scratchbird | Initial Early Beta (`0.1.0`) |
| Pascal | ScratchBird.Client | Initial Early Beta (`0.1.0`) |
| .NET | ScratchBird.Data | Initial Early Beta (`0.1.0`) |
| Java | scratchbird-jdbc | Initial Early Beta (`0.1.0`) |
| Elixir (Ecto) | scratchbird_ecto | In development (post-`0.1.0`) |
| Swift | ScratchBird | In development (post-`0.1.0`) |
| Dart | scratchbird | In development (post-`0.1.0`) |
| Mojo | scratchbird | In development (post-`0.1.0`) |

## Application Integrations

| Application | Type | Status |
|-------------|------|--------|
| Metabase | JDBC plugin | Scaffold |
| Superset | SQLAlchemy dialect | Scaffold |

## CLI Tools

| Tool | Purpose | Status |
|------|---------|--------|
| sb_isql | Native ScratchBird interactive shell | Implemented (baseline) |
| sb_fb_isql | Firebird protocol runner | Gated (requires FDW adapters + `SB_BUILD_CLI_FDW=ON`) |
| sb_pg_isql | PostgreSQL protocol runner | Gated (requires FDW adapters + `SB_BUILD_CLI_FDW=ON`) |
| sb_my_isql | MySQL protocol runner | Gated (requires FDW adapters + `SB_BUILD_CLI_FDW=ON`) |
| sb_admin | Administration CLI | Implemented (baseline) |
| sb_backup | Backup/restore CLI | Implemented (baseline) |
| sb_security | User/role CLI | Implemented (baseline) |
| sb_verify | Verification CLI | Implemented (baseline) |
| sbdriver-conformance | Conformance adapter | Implemented (baseline) |

## Requirements (Core Drivers)

- ScratchBird server with SBWP v1.1 enabled
- TLS 1.3 (enforced by core drivers)
- Binary transfer mode (enforced by core drivers; text mode rejected with SQLSTATE 0A000)

## Key Features (Core Drivers)

- **Server-side Prepare/Bind** - PARSE/BIND/EXECUTE for all parameterized queries
- **Streaming/Paging** - Portal paging via MSG_PORTAL_SUSPENDED
- **Type Coverage** - Full SBWP type matrix across released drivers; expansion continues on in-development drivers
- **SCRAM-SHA-256 Authentication** - Secure credential handling
- **Query Cancellation** - CANCEL messages with timeout enforcement

## Documentation

For detailed specifications, see the [docs/](https://github.com/DaltonCalford/ScratchBird-driver/tree/main/docs) directory in the repository.

**Last Updated:** 2026-02-18
