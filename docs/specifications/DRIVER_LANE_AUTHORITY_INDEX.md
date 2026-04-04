# Driver Lane Authority Index

This index names the single authoritative implementation-spec path, shared
release-evidence template path, and later verification packet for every
active Beta 1 driver/tooling/adapter lane.

| Lane | Kind | Current State | Benchmark | Implementation Spec | Release Evidence | Verification Packet |
| --- | --- | --- | --- | --- | --- | --- |
| `cpp` | `driver` | `baseline_complete` | `libpqxx` | `docs/specifications/drivers/language/cpp/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/cpp.md` |
| `cli` | `tooling` | `tooling_partial` | `psql` | `docs/specifications/drivers/CLI_TOOLS_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/cli.md` |
| `dart` | `driver` | `partial` | `postgres (Dart)` | `docs/specifications/DRIVER_DART_DATABASE_API.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/dart.md` |
| `dbeaver` | `adapter` | `partial_plugin` | `DBeaver PostgreSQL extension` | `docs/application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/dbeaver.md` |
| `dotnet` | `driver` | `baseline_complete` | `Npgsql` | `docs/specifications/drivers/language/dotnet-csharp/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/dotnet.md` |
| `elixir` | `driver` | `partial` | `Postgrex` | `docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/elixir.md` |
| `go` | `driver` | `baseline_complete` | `pgx` | `docs/specifications/drivers/language/golang/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/go.md` |
| `hibernate` | `adapter` | `partial_contract_only` | `Hibernate PostgreSQLDialect` | `docs/application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/hibernate.md` |
| `jdbc` | `driver` | `baseline_complete` | `pgjdbc` | `docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/jdbc.md` |
| `metabase` | `adapter` | `partial_adapter` | `Metabase PostgreSQL driver` | `docs/application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/metabase.md` |
| `mojo` | `driver` | `hybrid_native_gap` | `Composite (asyncpg + pgx + PostgresNIO)` | `docs/specifications/DRIVER_MOJO_NATIVE_API.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/mojo.md` |
| `node` | `driver` | `baseline_complete` | `node-postgres` | `docs/specifications/drivers/language/nodejs-typescript/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/node.md` |
| `odbc` | `driver` | `partial` | `Microsoft ODBC Driver for SQL Server` | `docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/odbc.md` |
| `pascal` | `driver` | `baseline_complete` | `FireDAC` | `docs/specifications/drivers/language/pascal-delphi/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/pascal.md` |
| `php` | `driver` | `baseline_complete` | `PDO_PGSQL` | `docs/specifications/drivers/language/php/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/php.md` |
| `prisma` | `adapter` | `partial_contract_only` | `Prisma PostgreSQL connector` | `docs/application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/prisma.md` |
| `python` | `driver` | `baseline_complete` | `psycopg3` | `docs/specifications/drivers/language/python/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/python.md` |
| `r` | `driver` | `partial` | `RPostgres` | `docs/specifications/drivers/language/r/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/r.md` |
| `ruby` | `driver` | `baseline_complete` | `ruby-pg` | `docs/specifications/drivers/language/ruby/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/ruby.md` |
| `rust` | `driver` | `baseline_complete` | `tokio-postgres` | `docs/specifications/drivers/language/rust/SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/rust.md` |
| `sqlalchemy` | `adapter` | `partial_adapter` | `SQLAlchemy PostgreSQL dialect` | `docs/application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/sqlalchemy.md` |
| `superset` | `adapter` | `partial_adapter` | `Superset PostgreSQL engine spec` | `docs/application-reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/superset.md` |
| `swift` | `driver` | `partial` | `PostgresNIO` | `docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/swift.md` |
| `typeorm` | `adapter` | `partial_contract_only` | `TypeORM PostgreSQL driver` | `docs/application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/typeorm.md` |
