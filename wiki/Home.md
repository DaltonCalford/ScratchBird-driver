# ScratchBird Drivers Wiki

Official native drivers for the ScratchBird database engine. All drivers target the ScratchBird Wire Protocol (SBWP v1.1) and require TLS 1.3.

## Project Status

ScratchBird is in early alpha release. No binaries have been officially released at this time. The code is ready to be built and tested if you want to setup your own test environment.

If you are curious, clone the directories and have your friendly local AI analyse the code base (documentation is out of date except for specifications) - tell it to find out the capabilities of the project from the implemented source code, not the comments or documentation. This will give you a good understanding of what is done and what is going to be done.

The drivers and management interface (ScratchBird-drivers and ScratchRobin) are getting heavy testing and updating. They are getting multiple commits per day on average.

The initial preview will be a docker containing the database engine and an app-image or standalone executable so that you can test the project without any problems of getting rid of it afterward.

This project has become my answer to the constant "Damn I wish I had the ability to...." issues I have encountered over 35 years of database use.

I have been seeing multiple clones of my project(s) via the tracker but I have not received any feedback yet - don't be afraid, I need feedback and I don't bite.

I am sure there are things others have encountered over the years and wish they had a tool to cover it.

Thanks for your interest in the project.

**Status:** Release prep (SBWP v1.1 baseline across drivers + CLI; conformance in progress)

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
| C/C++ | libscratchbird_client | Implemented (SBWP v1.1 baseline) |
| ODBC 3.8 | scratchbird_odbc | Implemented (SBWP v1.1 baseline) |
| Go | scratchbird-go | Implemented (SBWP v1.1 baseline) |
| Python | scratchbird | Implemented (SBWP v1.1 baseline) |
| Node.js | scratchbird | Implemented (SBWP v1.1 baseline) |
| Ruby | scratchbird | Implemented (SBWP v1.1 baseline) |
| Rust | scratchbird | Implemented (SBWP v1.1 baseline) |
| PHP | scratchbird | Implemented (SBWP v1.1 baseline) |
| R | scratchbird | Implemented (SBWP v1.1 baseline) |
| Pascal | ScratchBird.Client | Implemented (SBWP v1.1 baseline) |
| .NET | ScratchBird.Data | Implemented (SBWP v1.1 baseline) |
| Java | scratchbird-jdbc | Implemented (SBWP v1.1 baseline) |
| Elixir (Ecto) | scratchbird_ecto | Preview |
| Swift | ScratchBird | Preview |
| Dart | scratchbird | Preview |
| Mojo | scratchbird | Preview |

## Application Integrations

| Application | Type | Status |
|-------------|------|--------|
| Metabase | JDBC plugin | Scaffold |
| Superset | SQLAlchemy dialect | Scaffold |

## CLI Tools

| Tool | Purpose | Status |
|------|---------|--------|
| sb_isql | Native ScratchBird interactive shell | Implemented (baseline) |
| sb_fb_isql | Firebird protocol runner | Implemented (baseline) |
| sb_pg_isql | PostgreSQL protocol runner | Implemented (baseline) |
| sb_my_isql | MySQL protocol runner | Implemented (baseline) |
| sb_admin | Administration CLI | Implemented (baseline) |
| sb_backup | Backup/restore CLI | Implemented (baseline) |
| sb_security | User/role CLI | Implemented (baseline) |
| sb_verify | Verification CLI | Implemented (baseline) |
| sbdriver-conformance | Conformance adapter | Implemented (baseline) |

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

**Last Updated:** 2026-02-01
