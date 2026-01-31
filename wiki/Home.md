# ScratchBird Drivers Wiki

Official native drivers for the ScratchBird database engine. All drivers target the ScratchBird Wire Protocol (SBWP v1.1) and require TLS 1.3.

**Status:** Feature-complete for SBWP v1.1 (as of 2026-01-30)

## Overview

This repository contains drivers for 10 programming languages plus application integrations for Metabase and Superset. Each driver implements the native wire protocol for direct connections to ScratchBird on port 3092.

## Wiki Contents

- [Getting Started](Getting-Started) - Connection strings, DSN formats, quick examples
- [Drivers](Drivers) - Per-language installation and usage
- [Protocol and Specs](Protocol-and-Specs) - Wire protocol details and type mappings
- [Conformance Testing](Conformance-Testing) - Shared test harness for protocol compliance
- [Development](Development) - Build commands, testing, and release packaging
- [Metabase Driver](Metabase-Driver) - Metabase plugin installation
- [Superset Driver](Superset-Driver) - Apache Superset dialect

## Supported Drivers

| Language | Package/Module | Standard |
|----------|---------------|----------|
| Go | scratchbird-go | database/sql |
| Python | scratchbird | DB-API 2.0 |
| Node.js | scratchbird | Native async |
| Ruby | scratchbird | Native |
| Rust | scratchbird | Async (tokio) |
| PHP | scratchbird | PDO-style |
| R | scratchbird | DBI |
| Pascal | ScratchBird.Client | Native + adapters |
| .NET | ScratchBird.Data | ADO.NET |
| Java | scratchbird-jdbc | JDBC Type 4 |

## Application Integrations

| Application | Type | Status |
|-------------|------|--------|
| Metabase | JDBC plugin | Feature-complete |
| Superset | SQLAlchemy dialect | Feature-complete |

## Requirements

- ScratchBird server with SBWP v1.1 enabled
- TLS 1.3 (required for all connections)
- Binary transfer mode (text mode rejected with SQLSTATE 0A000)

## Key Features

- **Server-side Prepare/Bind** - PARSE/BIND/EXECUTE for all parameterized queries
- **Streaming/Paging** - Portal paging via MSG_PORTAL_SUSPENDED
- **Full Type Coverage** - ARRAY, COMPOSITE, GEOMETRY, VECTOR, RANGE support
- **SCRAM-SHA-256 Authentication** - Secure credential handling
- **Query Cancellation** - CANCEL messages with timeout enforcement

## Documentation

For detailed specifications, see the [docs/](https://github.com/DaltonCalford/ScratchBird-driver/tree/main/docs) directory in the repository.

**Last Updated:** 2026-01-30
