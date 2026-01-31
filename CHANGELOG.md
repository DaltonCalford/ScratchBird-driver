# Changelog

All notable changes to the ScratchBird Drivers project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- N/A

### Changed
- N/A

### Fixed
- N/A

---

## [0.1.0] - 2026-01-30

Initial feature-complete release targeting SBWP v1.1.

### Added

**Core Drivers**
- Go driver with database/sql compatibility
- Python driver with DB-API 2.0 compliance
- Node.js driver with TypeScript support
- Ruby driver with native API
- Rust driver with async/await (tokio) support
- PHP driver with PDO-style interface
- R driver with DBI compatibility
- Pascal driver with FireDAC/IBX/Zeos/SQLdb adapters
- .NET driver with ADO.NET compatibility
- JDBC driver (Type 4) for Java ecosystem

**Application Drivers**
- Metabase plugin using JDBC driver
- Superset dialect with SQLAlchemy integration

**Protocol Features**
- SBWP v1.1 wire protocol implementation across all drivers
- Server-side PARSE/BIND/EXECUTE (client-side substitution prohibited)
- TLS 1.3 required for all connections
- Binary-only transfer mode (text mode rejected with SQLSTATE 0A000)
- SCRAM-SHA-256 authentication
- Full wire type coverage including ARRAY, COMPOSITE, GEOMETRY, VECTOR, RANGE

**Streaming and Paging**
- Portal paging via MSG_PORTAL_SUSPENDED and EXECUTE max_rows
- Incremental fetch support in Python, R, and JDBC (avoid full buffering)
- Streaming APIs in Node.js, Ruby, Rust, PHP, Pascal, .NET

**Metadata Support**
- DESCRIBE integration for parameter/result metadata validation
- JDBC DatabaseMetaData: getPrimaryKeys, getImportedKeys, getTypeInfo via sys.* views
- Superset: get_pk_constraint, get_foreign_keys, get_indexes
- Metabase feature flags aligned with JDBC metadata coverage

**Timeout and Cancellation**
- Query timeout with CANCEL message (MSG_FLAG_URGENT)
- .NET CommandTimeout wired to timeoutMs/CANCEL
- JDBC query timeout enforcement with SQLSTATE 57014

**Configuration**
- Unified DSN/connection string format across all drivers
- Support for role, sslpassword, and all TLS options
- Key aliases for cross-driver compatibility (database/dbname, user/username, etc.)

**Testing Infrastructure**
- Shared conformance test harness with JSON manifest
- SQL fixtures for schema and type coverage testing
- Cross-platform CI (Windows/Linux) build matrix
- Per-driver environment variable configuration

**Documentation**
- Comprehensive API reference for all 12 drivers
- Getting started guides per language
- Wire protocol specifications
- Type mapping matrix
- Error mapping with SQLSTATE coverage
- GitHub wiki with synced content

### Changed
- zstd compression disabled until server-side support is implemented

### Security
- TLS 1.3 mandatory; sslmode=disable rejected by all drivers
- SCRAM-SHA-256 for authentication (no plaintext passwords over wire)
