# ScratchBird Database Drivers

Official drivers, tooling, and application adapters for the ScratchBird
Database Engine.

## Current State

This repository is in the Beta 1 driver program. The current audited state is:

- `10` application-driver lanes are `baseline_complete` against the repo's
  JDBC/.NET-class baseline:
  `cpp`, `dotnet`, `go`, `jdbc`, `node`, `pascal`, `php`, `python`, `ruby`,
  `rust`
- `5` application-driver lanes are still `partial`:
  `dart`, `elixir`, `odbc`, `r`, `swift`
- `1` driver lane is functionally strong but still has a native-architecture
  gap:
  `mojo`
- `1` tooling lane remains partial:
  `cli`
- `7` BI/application adapters are still partial or contract-first:
  `dbeaver`, `hibernate`, `metabase`, `prisma`, `sqlalchemy`, `superset`,
  `typeorm`

Authoritative status sources:

- [Driver implementation audit](docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md)
- [Lane authority index](docs/specifications/DRIVER_LANE_AUTHORITY_INDEX.md)
- [Server-blocked remaining work](docs/audit/DRIVER_SERVER_BLOCKED_REMAINING_WORK.md)

## Where To Start

- [Getting started](docs/getting-started/README.md)
- [API reference](docs/api-reference/README.md)
- [Application adapter reference](docs/application-reference/README.md)
- [Specifications](docs/specifications/README.md)
- [Audit reports](docs/audit/README.md)
- [Development and verification docs](docs/development/README.md)

## Driver Lanes

| Lane | Current State | Benchmark | Public Docs |
| --- | --- | --- | --- |
| `cpp` | `baseline_complete` | `libpqxx` | [guide](docs/getting-started/cpp.md) / [api](docs/api-reference/cpp.md) |
| `dart` | `partial` | `postgres (Dart)` | [guide](docs/getting-started/dart.md) / [api](docs/api-reference/dart.md) |
| `dotnet` | `baseline_complete` | `Npgsql` | [guide](docs/getting-started/dotnet.md) / [api](docs/api-reference/dotnet.md) |
| `elixir` | `partial` | `Postgrex` | [guide](docs/getting-started/elixir.md) / [api](docs/api-reference/elixir.md) |
| `go` | `baseline_complete` | `pgx` | [guide](docs/getting-started/go.md) / [api](docs/api-reference/go.md) |
| `jdbc` | `baseline_complete` | `pgjdbc` | [guide](docs/getting-started/jdbc.md) / [api](docs/api-reference/jdbc.md) |
| `mojo` | `hybrid_native_gap` | `Composite (asyncpg + pgx + PostgresNIO)` | [guide](docs/getting-started/mojo.md) / [api](docs/api-reference/mojo.md) |
| `node` | `baseline_complete` | `node-postgres` | [guide](docs/getting-started/node.md) / [api](docs/api-reference/node.md) |
| `odbc` | `partial` | `Microsoft ODBC Driver for SQL Server` | [guide](docs/getting-started/odbc.md) / [api](docs/api-reference/odbc.md) |
| `pascal` | `baseline_complete` | `FireDAC` | [guide](docs/getting-started/pascal.md) / [api](docs/api-reference/pascal.md) |
| `php` | `baseline_complete` | `PDO_PGSQL` | [guide](docs/getting-started/php.md) / [api](docs/api-reference/php.md) |
| `python` | `baseline_complete` | `psycopg3` | [guide](docs/getting-started/python.md) / [api](docs/api-reference/python.md) |
| `r` | `partial` | `RPostgres` | [guide](docs/getting-started/r.md) / [api](docs/api-reference/r.md) |
| `ruby` | `baseline_complete` | `ruby-pg` | [guide](docs/getting-started/ruby.md) / [api](docs/api-reference/ruby.md) |
| `rust` | `baseline_complete` | `tokio-postgres` | [guide](docs/getting-started/rust.md) / [api](docs/api-reference/rust.md) |
| `swift` | `partial` | `PostgresNIO` | [guide](docs/getting-started/swift.md) / [api](docs/api-reference/swift.md) |

## Tooling And Adapters

| Lane | Current State | Benchmark | Public Docs |
| --- | --- | --- | --- |
| `cli` | `tooling_partial` | `psql` | [guide](docs/getting-started/cli.md) / [api](docs/api-reference/cli.md) |
| `dbeaver` | `partial_plugin` | `DBeaver PostgreSQL extension` | [guide](docs/getting-started/dbeaver.md) / [api](docs/api-reference/dbeaver.md) |
| `hibernate` | `partial_contract_only` | `Hibernate PostgreSQLDialect` | [guide](docs/getting-started/hibernate.md) / [api](docs/api-reference/hibernate.md) |
| `metabase` | `partial_adapter` | `Metabase PostgreSQL driver` | [guide](docs/getting-started/metabase.md) / [api](docs/api-reference/metabase.md) |
| `prisma` | `partial_contract_only` | `Prisma PostgreSQL connector` | [guide](docs/getting-started/prisma.md) / [api](docs/api-reference/prisma.md) |
| `sqlalchemy` | `partial_adapter` | `SQLAlchemy PostgreSQL dialect` | [guide](docs/getting-started/sqlalchemy.md) / [api](docs/api-reference/sqlalchemy.md) |
| `superset` | `partial_adapter` | `Superset PostgreSQL engine spec` | [guide](docs/getting-started/superset.md) / [api](docs/api-reference/superset.md) |
| `typeorm` | `partial_contract_only` | `TypeORM PostgreSQL driver` | [guide](docs/getting-started/typeorm.md) / [api](docs/api-reference/typeorm.md) |

## Release Evidence And Verification

Every lane is expected to ship with a deterministic evidence pack and a later
live verification packet.

- Shared evidence contract:
  [DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md](docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md)
- Evidence templates:
  [docs/development/release-evidence/README.md](docs/development/release-evidence/README.md)
- Later live verification packets:
  [docs/development/server-verification/README.md](docs/development/server-verification/README.md)

## Repository Layout

```text
ScratchBird-driver/
├── docs/
│   ├── api-reference/
│   ├── application-reference/
│   ├── audit/
│   ├── development/
│   ├── getting-started/
│   ├── planning/
│   ├── reference/
│   └── specifications/
├── scripts/
├── tracks/
│   ├── alpha/
│   ├── beta/
│   └── p3/
└── wiki/
```

## Notes

- ScratchBird drivers follow the engine MGA/state-recovery model.
- Driver reconnect logic restores transport/session state; it does not replay
  or resurrect lost in-flight transactions.
- For current user-facing behavior, prefer the getting-started and API
  reference pages over older planning artifacts.

Last updated: 2026-04-03
