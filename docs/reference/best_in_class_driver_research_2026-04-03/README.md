# Best-In-Class Driver Research Packet (2026-04-03)

This packet captures best-in-class benchmark selection, downloaded
reference sources, implementation anchors, and competitive closure
inputs for every Beta 1 class driver, CLI, and BI/application adapter
lane in `ScratchBird-driver`.

## Lane Summary

| Lane | Surface | Selected Benchmark | Current State |
| --- | --- | --- | --- |
| cpp | C/C++ driver | libpqxx | full_parity |
| cli | CLI tooling lane | psql | partial_tooling |
| dart | Dart driver | postgres (Dart) | partial |
| dbeaver | DBeaver integration | DBeaver PostgreSQL extension | partial_plugin |
| dotnet | .NET driver | Npgsql | full_parity |
| elixir | Elixir/Ecto driver | Postgrex | partial |
| go | Go driver | pgx | full_parity |
| hibernate | Hibernate dialect | Hibernate PostgreSQLDialect | partial_contract_only |
| jdbc | JDBC driver | pgjdbc | full_parity |
| metabase | Metabase adapter | Metabase PostgreSQL driver | partial_adapter |
| mojo | Mojo driver | Composite (asyncpg + pgx + PostgresNIO) | hybrid_native_gap |
| node | Node.js/TypeScript driver | node-postgres | full_parity |
| odbc | ODBC driver | Microsoft ODBC Driver for SQL Server | partial |
| pascal | Pascal/Delphi driver | FireDAC | full_parity |
| php | PHP driver | PDO_PGSQL | full_parity |
| prisma | Prisma adapter | Prisma PostgreSQL connector | partial_contract_only |
| python | Python driver | psycopg3 | full_parity |
| r | R driver | RPostgres | partial |
| ruby | Ruby driver | ruby-pg | full_parity |
| rust | Rust driver | tokio-postgres | full_parity |
| sqlalchemy | SQLAlchemy dialect | SQLAlchemy PostgreSQL dialect | partial_adapter |
| superset | Superset adapter | Superset PostgreSQL engine spec | partial_adapter |
| swift | Swift driver | PostgresNIO | partial |
| typeorm | TypeORM adapter | TypeORM PostgreSQL driver | partial_contract_only |

## Packet Contents

Every lane folder contains:

- `REFERENCE_MANIFEST.csv`
- `BEST_IN_CLASS_SELECTION.md`
- `COMPETITIVE_FEATURE_MATRIX.csv`
- `IMPLEMENTATION_ANCHORS.md`
- `downloads/`
