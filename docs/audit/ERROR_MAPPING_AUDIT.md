# Error Mapping Audit (vs DRIVER_ERROR_MAPPING.md)

Status: Draft
Last Updated: 2026-02-04

## Scope

Audited driver error mapping implementations for SQLSTATE parsing and mapping
per `docs/specifications/DRIVER_ERROR_MAPPING.md`.

## Summary

- Core drivers (Go/Node/Python/Ruby/Rust/PHP/R/Pascal/.NET/JDBC/ODBC) parse
  SQLSTATE and map by class-prefix.
- C++ client maps internal Status codes to SQLSTATE (class-prefix style).
- Dart and Swift do not currently parse SQLSTATE or map to typed errors.
- Elixir parses SQLSTATE fields but does not appear to map by class prefix.

## Evidence (Selected)

### Go
- `tracks/p3/drivers/go/errors.go`: `mapSQLState` maps 01/02/08/0A/22/23/28/40/42/53/54/57/58/XX.

### Node.js/TypeScript
- `tracks/p3/drivers/node/src/errors.ts`: `mapSqlState` maps 01/02/08/0A/22/23/28/40/42/53/54/57/58/XX.

### Python
- `tracks/p3/drivers/python/src/scratchbird/connection.py`: `_map_sqlstate` maps 01/02/08/0A/22/23/28/40/42/53/54/57/58/XX.

### Ruby
- `tracks/p3/drivers/ruby/lib/scratchbird/errors.rb`: `ErrorMapper.from_sqlstate` maps 01/02/08/0A/22/23/28/40/42/53/54/57/58/XX.

### Rust
- `tracks/p3/drivers/rust/src/errors.rs`: `error_from_sqlstate` maps 01/02/08/0A/22/23/28/40/42/53/54/57/58/XX.

### PHP
- `tracks/p3/drivers/php/src/Errors.php`: `ErrorMapper::map` maps 01/02/08/0A/22/23/28/40/42/53/54/57/58/XX.

### R
- `tracks/p3/drivers/r/R/protocol.R`: parses sqlstate fields.
- `tracks/p3/drivers/r/R/client.R`: prefixes errors with `[SQLSTATE]`.

### Pascal/Delphi
- `tracks/p3/drivers/pascal/src/ScratchBird.Errors.pas`: `MapSqlState` class-prefix mapping.

### .NET
- `tracks/p3/drivers/dotnet/src/ScratchBird.Data/Errors.cs`: `ScratchBirdSqlStateMapper` class-prefix mapping.

### JDBC
- `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java`: parses sqlstate; mapped to `SQLException`.

### C/C++
- `tracks/p3/drivers/cpp/src/core/sqlstate.cpp`: internal Status -> SQLSTATE mapping.

### Dart
- No SQLSTATE parsing or mapping found in `tracks/p3/drivers/dart/lib/`.

### Swift
- No SQLSTATE parsing or mapping found in `tracks/p3/drivers/swift/Sources/`.

### Elixir
- SQLSTATE parsing in `tracks/p3/drivers/elixir/lib/scratchbird/protocol.ex`; mapping not observed.

## Open Gaps

1. Add SQLSTATE parsing/mapping to Dart and Swift.
2. Implement class-prefix mapping in Elixir (or align with spec alternative).
3. Consider upgrading core drivers to per-code SQLSTATE mapping where needed.
