# Language Driver Specifications

Status: Current

This directory contains the authoritative per-language driver specification
packages for the active lane-local language drivers.

## Current Status

| Lane | Current State | Benchmark |
| --- | --- | --- |
| `cpp` | `baseline_complete` | `libpqxx` |
| `dotnet-csharp` | `baseline_complete` | `Npgsql` |
| `golang` | `baseline_complete` | `pgx` |
| `nodejs-typescript` | `baseline_complete` | `node-postgres` |
| `pascal-delphi` | `baseline_complete` | `FireDAC` |
| `php` | `baseline_complete` | `PDO_PGSQL` |
| `python` | `baseline_complete` | `psycopg3` |
| `r` | `partial` | `RPostgres` |
| `ruby` | `baseline_complete` | `ruby-pg` |
| `rust` | `baseline_complete` | `tokio-postgres` |

Top-level driver lanes are tracked in:

- `docs/specifications/DRIVER_DART_DATABASE_API.md`
- `docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md`
- `docs/specifications/DRIVER_MOJO_NATIVE_API.md`
- `docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md`
- `docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md`
- `docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md`

See `docs/specifications/DRIVER_LANE_AUTHORITY_INDEX.md` for the full
cross-lane authority map.
