# ScratchBird Drivers Wiki

Official native drivers for the ScratchBird database engine. All drivers target the ScratchBird Wire Protocol (SBWP v1.1) and require TLS 1.3.

## Overview

This repository contains drivers for 10 programming languages plus a Metabase plugin. Each driver implements the native wire protocol for direct connections to ScratchBird on port 3092.

## Wiki Contents

- [Getting Started](Getting-Started) - Connection strings, DSN formats, quick examples
- [Drivers](Drivers) - Per-language installation and usage
- [Protocol and Specs](Protocol-and-Specs) - Wire protocol details and type mappings
- [Conformance Testing](Conformance-Testing) - Shared test harness for protocol compliance
- [Development](Development) - Build commands, testing, and release packaging
- [Metabase Driver](Metabase-Driver) - Metabase plugin installation

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

## Requirements

- ScratchBird server with SBWP v1.1 enabled
- TLS 1.3 (required for all connections)
- Binary transfer mode (text mode not supported)

## Status

All drivers are in active development targeting SBWP v1.1.
