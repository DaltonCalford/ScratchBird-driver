# Server Verification Packets

These packets define the exact later verification steps that remain once a
working ScratchBird test server is available.

They now cover both:

- currently implemented or partially implemented lanes
- newly promoted `planned_beta1` lanes whose specification packs are complete
  but whose code and measured release evidence still need to be produced

| Lane | Benchmark | Current State | Packet |
| --- | --- | --- | --- |
| `adbc` | `Apache Arrow ADBC PostgreSQL driver` | `planned_beta1` | [adbc.md](adbc.md) |
| `airbyte` | `Airbyte PostgreSQL source/destination` | `planned_beta1` | [airbyte.md](airbyte.md) |
| `cpp` | `libpqxx` | `baseline_complete` | [cpp.md](cpp.md) |
| `cli` | `psql` | `tooling_partial` | [cli.md](cli.md) |
| `dart` | `postgres (Dart)` | `partial` | [dart.md](dart.md) |
| `dbeaver` | `DBeaver PostgreSQL extension` | `partial_plugin` | [dbeaver.md](dbeaver.md) |
| `dbt` | `dbt-postgres` | `planned_beta1` | [dbt.md](dbt.md) |
| `dotnet` | `Npgsql` | `baseline_complete` | [dotnet.md](dotnet.md) |
| `elixir` | `Postgrex` | `partial` | [elixir.md](elixir.md) |
| `flightsql` | `Apache Arrow Flight SQL client stack` | `planned_beta1` | [flightsql.md](flightsql.md) |
| `go` | `pgx` | `baseline_complete` | [go.md](go.md) |
| `hibernate` | `Hibernate PostgreSQLDialect` | `partial_contract_only` | [hibernate.md](hibernate.md) |
| `jdbc` | `pgjdbc` | `baseline_complete` | [jdbc.md](jdbc.md) |
| `julia` | `LibPQ.jl` | `planned_beta1` | [julia.md](julia.md) |
| `looker` | `Looker PostgreSQL dialect` | `planned_beta1` | [looker.md](looker.md) |
| `metabase` | `Metabase PostgreSQL driver` | `partial_adapter` | [metabase.md](metabase.md) |
| `mojo` | `Composite (asyncpg + pgx + PostgresNIO)` | `hybrid_native_gap` | [mojo.md](mojo.md) |
| `node` | `node-postgres` | `baseline_complete` | [node.md](node.md) |
| `odbc` | `Microsoft ODBC Driver for SQL Server` | `partial` | [odbc.md](odbc.md) |
| `pascal` | `FireDAC` | `baseline_complete` | [pascal.md](pascal.md) |
| `perl` | `DBD::Pg` | `planned_beta1` | [perl.md](perl.md) |
| `php` | `PDO_PGSQL` | `baseline_complete` | [php.md](php.md) |
| `powerbi` | `Power BI PostgreSQL / ODBC custom connector surface` | `planned_beta1` | [powerbi.md](powerbi.md) |
| `prisma` | `Prisma PostgreSQL connector` | `partial_contract_only` | [prisma.md](prisma.md) |
| `python` | `psycopg3` | `baseline_complete` | [python.md](python.md) |
| `r` | `RPostgres` | `partial` | [r.md](r.md) |
| `r2dbc` | `PostgreSQL R2DBC driver` | `planned_beta1` | [r2dbc.md](r2dbc.md) |
| `ruby` | `ruby-pg` | `baseline_complete` | [ruby.md](ruby.md) |
| `rust` | `tokio-postgres` | `baseline_complete` | [rust.md](rust.md) |
| `sqlalchemy` | `SQLAlchemy PostgreSQL dialect` | `partial_adapter` | [sqlalchemy.md](sqlalchemy.md) |
| `superset` | `Superset PostgreSQL engine spec` | `partial_adapter` | [superset.md](superset.md) |
| `swift` | `PostgresNIO` | `partial` | [swift.md](swift.md) |
| `tableau` | `Tableau PostgreSQL / Named Connector SDK` | `planned_beta1` | [tableau.md](tableau.md) |
| `typeorm` | `TypeORM PostgreSQL driver` | `partial_contract_only` | [typeorm.md](typeorm.md) |
