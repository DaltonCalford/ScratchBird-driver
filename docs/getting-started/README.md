# Getting Started

This section provides installation and first-connection guidance for ScratchBird
drivers in this repository. Released drivers enforce full SBWP v1.1 requirements;
in-development drivers are partial and may not enforce all requirements yet.

## Common Requirements

- ScratchBird server with the native listener enabled (default port 3092)
- TLS 1.3 is required for released drivers (in-development drivers may not enforce yet)
- SBWP v1.1 protocol support
- Binary transfer must remain enabled (`binary_transfer=true`) for core drivers

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
