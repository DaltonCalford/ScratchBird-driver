# Getting Started

This section provides installation and first-connection guidance for every
ScratchBird driver in this repository.

## Common Requirements

- ScratchBird server with the native listener enabled (default port 3092)
- TLS 1.3 is required for all drivers
- SBWP v1.1 protocol support
- Binary transfer must remain enabled (`binary_transfer=true`)

## Driver Guides

- [Go](go.md)
- [Python](python.md)
- [Node.js](node.md)
- [Ruby](ruby.md)
- [Rust](rust.md)
- [PHP](php.md)
- [R](r.md)
- [Pascal/Delphi](pascal.md)
- [.NET](dotnet.md)
- [JDBC (Java)](jdbc.md)
- [Elixir (Ecto)](elixir.md)
- [Swift](swift.md)
- [Dart](dart.md)
- [Mojo](mojo.md)
- [Metabase Plugin](metabase.md)
- [Superset Driver](superset.md)

## CLI Tools

CLI documentation lives in `docs/user-documentation/tools/`:

- [CLI tool index](../user-documentation/tools/README.md)

## Shared References

- [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md)
- [Type mapping matrix](../specifications/TYPE_MAPPING_MATRIX.md)
- [Prepare/bind requirements](../specifications/PREPARE_BIND_REQUIREMENTS.md)
- [Conformance fixtures](../fixtures/README.md)
