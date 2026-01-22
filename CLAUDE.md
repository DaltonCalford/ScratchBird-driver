# Claude Code Context - ScratchBird Drivers

## Project Overview

This repository contains native database drivers for the ScratchBird database engine. Drivers are implemented in 10 programming languages, each following idiomatic patterns for their respective ecosystems.

## Key References

| Document | Purpose |
|----------|---------|
| `README.md` | Project overview and quick start |
| `CONTRIBUTING.md` | Development guidelines per language |
| `docs/` | Documentation structure |
| Parent: [ScratchBird](https://github.com/DaltonCalford/ScratchBird) | Main database engine |

## Driver Structure

Each driver follows a similar pattern:
- `src/` or `lib/` - Main source code
- `tests/` or `test/` - Test suite
- Language-specific config (go.mod, pyproject.toml, package.json, Cargo.toml, etc.)
- `README.md` - Driver-specific documentation

## Language Directories

| Directory | Language | Entry Point |
|-----------|----------|-------------|
| `go/` | Go | `scratchbird.go` |
| `python/` | Python | `src/scratchbird/` |
| `node/` | Node.js/TS | `src/` |
| `ruby/` | Ruby | `lib/` |
| `rust/` | Rust | `src/lib.rs` |
| `php/` | PHP | `src/` |
| `r/` | R | `R/` |
| `pascal/` | Pascal | `src/` |
| `dotnet/` | C#/.NET | `src/` |
| `jdbc/` | Java | `src/main/java/` |

## Wire Protocol

All drivers implement the ScratchBird native wire protocol (port 3092). Key components:
- Connection handshake
- Authentication (SCRAM-SHA-256)
- Query execution
- Result set handling
- Transaction management

See main ScratchBird project for protocol specifications.

## Development Workflow

1. Read the driver-specific README
2. Set up the language toolchain
3. Run existing tests to verify setup
4. Make changes following language conventions
5. Add tests for new functionality
6. Update documentation as needed

## Testing

Each driver has its own test suite. Integration tests require a running ScratchBird server.

```bash
# Example test commands
cd go && go test ./...
cd python && pytest
cd node && npm test
cd rust && cargo test
```

## Important Notes

- Drivers should follow idiomatic patterns for each language
- All drivers must support the core feature set (connections, queries, transactions)
- Authentication must use SCRAM-SHA-256
- TLS support is required for production use
- Follow the CONTRIBUTING.md guidelines for each language
