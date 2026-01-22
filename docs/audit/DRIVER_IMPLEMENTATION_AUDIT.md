# ScratchBird Driver Implementation Audit

Status: Draft
Last Updated: 2026-01-09
Scope: All drivers in this repo (native ScratchBird only)

## Summary

The drivers currently implement a legacy SBDB-style protocol and rely on
client-side SQL substitution for parameters. This is incompatible with
SBWP v1.1 and does not meet the native prepare/bind requirement.

## Findings

### 1) Protocol mismatch (SBDB vs SBWP)

All non-JDBC drivers use a 12-byte SBDB header (magic 0x42444253) instead of
SBWP v1.1's 40-byte header and attachment/txn IDs.

- Go: `go/protocol.go:10`
- Node: `node/src/protocol.ts:3`
- Python: `python/src/scratchbird/protocol.py:10`
- Ruby: `ruby/lib/scratchbird/protocol.rb:3`
- Rust: `rust/src/protocol.rs:5`
- PHP: `php/src/Protocol.php:7`
- R: `r/R/protocol.R:1`
- Pascal: `pascal/src/ScratchBird.Protocol.pas:9`
- .NET: `dotnet/src/ScratchBird.Data/WireProtocol.cs:140`

JDBC uses a PostgreSQL-style message set, not SBWP:

- `jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java:33`

### 2) Client-side parameter substitution (no server-side BIND)

Every driver renders parameters into SQL strings instead of using PARSE/BIND.

- Go: `go/query.go:11`
- Node: `node/src/client.ts:186`
- Python: `python/src/scratchbird/cursor.py:31`
- Rust: `rust/src/sql.rs:140`
- Ruby: `ruby/lib/scratchbird/sql.rb:8`
- PHP: `php/src/Sql.php:7`
- R: `r/R/sql.R:1`
- .NET: `dotnet/src/ScratchBird.Data/SqlHelpers.cs:9`
- JDBC: `jdbc/src/main/java/com/scratchbird/jdbc/SBPreparedStatement.java:110`

Prepared statements are not sent to the server (examples):

- Go Prepare returns a local Stmt only: `go/conn.go:219`
- Node prepare caches SQL in memory: `node/src/client.ts:197`

### 3) Wire type coverage gaps

Several drivers define composite/geometry/macaddr/range but do not decode them,
or omit them entirely.

- Go: types defined at `go/protocol.go:84` but not decoded in `go/types.go:13`
- Node: types defined at `node/src/types.ts:54` but not decoded in `node/src/types.ts:135`
- Python: types defined at `python/src/scratchbird/protocol.py:97` but not decoded in `python/src/scratchbird/types.py:24`
- Rust: WireType omits composite/geometry/macaddr/range in `rust/src/types.rs:10`
- Ruby: wire constants omit composite/geometry/macaddr/range in `ruby/lib/scratchbird/types.rb:5`
- PHP: wire constants omit composite/geometry/macaddr/range in `php/src/TypeDecoder.php:8`
- R: wire constants omit composite/geometry/macaddr/range in `r/R/types.R:1`
- .NET: types defined at `dotnet/src/ScratchBird.Data/WireProtocol.cs:54` but not decoded in `dotnet/src/ScratchBird.Data/TypeDecoder.cs:9`
- Pascal: WireTypeName includes composite/geometry/macaddr/range at `pascal/src/ScratchBird.Types.pas:116` but DecodeValue omits them at `pascal/src/ScratchBird.Types.pas:78`

### 4) Schema/search path not applied

- Python parses search_path but never applies it to the session: `python/src/scratchbird/connection.py:47`
- JDBC exposes currentSchema/searchPath but never issues a schema change: `jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionProperties.java:148`

### 5) JDBC metadata stubs

DatabaseMetaData methods return empty result sets for core metadata:

- getTables: `jdbc/src/main/java/com/scratchbird/jdbc/SBDatabaseMetaData.java:661`
- getSchemas: `jdbc/src/main/java/com/scratchbird/jdbc/SBDatabaseMetaData.java:679`
- getColumns: `jdbc/src/main/java/com/scratchbird/jdbc/SBDatabaseMetaData.java:716`

### 6) Cancellation not implemented (.NET)

- Cancel is a stub: `dotnet/src/ScratchBird.Data/ScratchBirdCommand.cs:166`

### 7) Documentation overstated features

Repository README claims native protocol parity, TLS, and prepared statements
across all drivers, but the implementations above do not meet those claims.

- `README.md:95`

## Required Remediation

See `docs/planning/DRIVER_REMEDIATION_PLAN.md` and the specifications in
`docs/specifications/` for the required changes.
