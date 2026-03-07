# Getting Started

This section provides installation and first-connection guidance for ScratchBird
drivers in this repository.

## Common Requirements

- ScratchBird server with the native listener enabled (default port 3092)
- SBWP v1.1 protocol support
- A user/database pair with permissions for the target workload

## Shared Connection Options

JDBC-parity lanes now expose a broader common connection surface than the early
alpha docs captured:

- Direct/native DSNs accept the standard `sslmode` values
  (`disable|allow|prefer|require|verify-ca|verify-full`).
- JDBC-parity lanes may also accept compatibility startup settings such as
  `binary_transfer=false` and `compression=zstd|none|off`; partial lanes document
  exceptions in their own guide.
- Managed ingress uses
  `front_door_mode=manager_proxy&manager_auth_token=...`.
- Auth-plugin-aware lanes also accept handshake inputs such as
  `client_flags|connect_client_flags`, `auth_method_payload`,
  `auth_required_methods`, `auth_forbidden_methods`,
  `auth_require_channel_binding`, `workload_identity_token`, and
  `proxy_principal_assertion`.

Use TLS-enabled modes in production. The per-driver guides below call out lane
differences where parity is still incomplete.

## Driver Guides

- [C/C++](cpp.md)
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
- [ODBC](odbc.md)
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

- [Connection modes and auth](../user-documentation/connectivity/connection-modes-and-auth.md)
- [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md)
- [Type mapping matrix](../specifications/TYPE_MAPPING_MATRIX.md)
- [Prepare/bind requirements](../specifications/PREPARE_BIND_REQUIREMENTS.md)
- [Conformance fixtures](../fixtures/README.md)
