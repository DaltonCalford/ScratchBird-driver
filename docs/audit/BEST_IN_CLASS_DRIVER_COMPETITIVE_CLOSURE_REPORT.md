# Best-In-Class Competitive Closure Report

Date: 2026-04-03

This report consolidates the benchmark selections and top closure areas
for every Beta 1 class driver and adapter lane.

## C/C++ driver

- Lane: `cpp`
- Selected benchmark: `libpqxx`
- Current state: `full_parity`

Top gaps:
- Add benchmark-backed performance and memory-footprint evidence comparable to libpqxx’s mature deployment posture.
- Tighten diagnostic and tracing documentation so operational debugging is as easy as the incumbent C++ stack.
- Expand package/distribution guidance for Linux, Windows, and ABI-safe consumption.

## CLI tooling lane

- Lane: `cli`
- Selected benchmark: `psql`
- Current state: `partial_tooling`

Top gaps:
- Close metadata and schema-browser coverage so CLI tooling can match psql-style introspection depth.
- Expand scripting/import/export and output-format ergonomics to compete with psql and usql automation flows.
- Improve platform packaging and runtime portability beyond Linux-first coverage.

## Dart driver

- Lane: `dart`
- Selected benchmark: `postgres (Dart)`
- Current state: `partial`

Top gaps:
- Complete transaction failure-path, suspend/resume, and resilience proof to the level expected by the leading Dart driver.
- Fill metadata restriction and DDL payload coverage gaps for tooling ecosystems.
- Broaden live complex-type codecs and runtime SQLSTATE/error propagation proof.

## DBeaver integration

- Lane: `dbeaver`
- Selected benchmark: `DBeaver PostgreSQL extension`
- Current state: `partial_plugin`

Top gaps:
- Expand navigator and schema-tree behavior to match the first-party DBeaver extensions without resorting to manual toggles.
- Add explain/plan, DDL editor, and richer metadata view integration.
- Harden stock-install and update-site packaging/documentation for enterprise installs.

## .NET driver

- Lane: `dotnet`
- Selected benchmark: `Npgsql`
- Current state: `full_parity`

Top gaps:
- Publish benchmark and operational evidence at the same standard expected of top-tier ADO.NET providers.
- Tighten integration guidance for ORMs, diagnostics, and pooling scenarios.
- Surface advanced provider ergonomics and troubleshooting guidance more directly in docs.

## Elixir/Ecto driver

- Lane: `elixir`
- Selected benchmark: `Postgrex`
- Current state: `partial`

Top gaps:
- Expose standalone public stream/paging helpers and stronger deterministic stream proof.
- Close the remaining resilience gap so reconnect/recovery behavior is competitive with Postgrex operationally.
- Document telemetry and Ecto integration expectations as first-class contractual requirements.

## Go driver

- Lane: `go`
- Selected benchmark: `pgx`
- Current state: `full_parity`

Top gaps:
- Strengthen benchmark-backed evidence for high-concurrency and large-result performance.
- Refine documentation around pooling, cancellation, and advanced codecs to exceed pgx usability.
- Broaden ecosystem guidance for ORMs and migration tools.

## Hibernate dialect

- Lane: `hibernate`
- Selected benchmark: `Hibernate PostgreSQLDialect`
- Current state: `partial_contract_only`

Top gaps:
- Move from deterministic dialect helpers to full schema tooling, DDL generation, and entity lifecycle validation.
- Close pagination, locking, generated key, and type contribution gaps against the strongest PostgreSQL dialect behavior.
- Add migration and integration-test evidence instead of relying only on contract-unit coverage.

## JDBC driver

- Lane: `jdbc`
- Selected benchmark: `pgjdbc`
- Current state: `full_parity`

Top gaps:
- Benchmark and publish metadata breadth, large-object, batch, and performance evidence at pgjdbc quality.
- Tighten framework-facing guidance for Hibernate, Spring, BI tooling, and migration ecosystems.
- Raise packaging/release cadence documentation to the standard of major JDBC providers.

## Metabase adapter

- Lane: `metabase`
- Selected benchmark: `Metabase PostgreSQL driver`
- Current state: `partial_adapter`

Top gaps:
- Close schema sync and field fingerprinting depth gaps so Metabase behavior matches the leading first-party plugins.
- Harden capability flags, native query handling, and packaging/deployment guidance.
- Add full end-to-end plugin validation against modern Metabase runtimes.

## Mojo driver

- Lane: `mojo`
- Selected benchmark: `Composite (asyncpg + pgx + PostgresNIO)`
- Current state: `hybrid_native_gap`

Top gaps:
- Replace the Python bridge with a native transport/runtime path.
- Close native TLS, streaming, type-wrapper, and packaging gaps using the composite benchmark as the target bar.
- Add first-class examples and performance proof once the transport cutover lands.

## Node.js/TypeScript driver

- Lane: `node`
- Selected benchmark: `node-postgres`
- Current state: `full_parity`

Top gaps:
- Publish benchmark and operational evidence at the level expected from top Node drivers.
- Refine cancellation, cursor, and pool troubleshooting guidance for framework integrators.
- Broaden examples for TypeScript-heavy application patterns.

## ODBC driver

- Lane: `odbc`
- Selected benchmark: `Microsoft ODBC Driver for SQL Server`
- Current state: `partial`

Top gaps:
- Close full-family metadata and catalog-surface gaps against the strongest ODBC drivers.
- Broaden descriptor, cursor, and diagnostics coverage where the commercial benchmark is stronger.
- Improve platform packaging and installation guidance across Windows and Linux.

## Pascal/Delphi driver

- Lane: `pascal`
- Selected benchmark: `FireDAC`
- Current state: `full_parity`

Top gaps:
- Raise packaging, IDE, and operational guidance to the standard expected by Delphi developers.
- Add richer dataset- and component-oriented examples and validation.
- Publish performance and release evidence to support commercial-grade evaluation.

## PHP driver

- Lane: `php`
- Selected benchmark: `PDO_PGSQL`
- Current state: `full_parity`

Top gaps:
- Expand packaging and framework guidance to match the clarity of mainstream PHP database stacks.
- Publish benchmark and memory/streaming evidence for long-running app workloads.
- Add more typed error and parameter-binding examples for PDO-style adopters.

## Prisma adapter

- Lane: `prisma`
- Selected benchmark: `Prisma PostgreSQL connector`
- Current state: `partial_contract_only`

Top gaps:
- Move from deterministic helper scaffolding to a full provider-quality introspection and migration surface.
- Close datasource validation, schema reflection, and transaction/runtime behavior gaps.
- Add packaging and framework-facing integration guidance for Prisma users.

## Python driver

- Lane: `python`
- Selected benchmark: `psycopg3`
- Current state: `full_parity`

Top gaps:
- Publish benchmark and async/runtime evidence at the standard expected by top Python drivers.
- Broaden packaging and framework integration guidance beyond baseline usage.
- Strengthen documentation for advanced codecs, cancellation, and copy/stream patterns.

## R driver

- Lane: `r`
- Selected benchmark: `RPostgres`
- Current state: `partial`

Top gaps:
- Close connection/auth environment-gated proof and stronger runtime examples.
- Expand metadata, DDL-editor, and privilege-related introspection parity.
- Improve packaging, reproducibility, and data-frame shaping evidence for R users.

## Ruby driver

- Lane: `ruby`
- Selected benchmark: `ruby-pg`
- Current state: `full_parity`

Top gaps:
- Publish benchmark, packaging, and Rails-oriented guidance at the standard expected by the top Ruby database gems.
- Broaden documentation around encoding, copy/streaming, and operational diagnostics.

## Rust driver

- Lane: `rust`
- Selected benchmark: `tokio-postgres`
- Current state: `full_parity`

Top gaps:
- Publish benchmark and concurrency evidence at the standard of the leading Rust async drivers.
- Expand framework, migration, and ecosystem integration guidance.
- Broaden observability and troubleshooting examples for async workloads.

## SQLAlchemy dialect

- Lane: `sqlalchemy`
- Selected benchmark: `SQLAlchemy PostgreSQL dialect`
- Current state: `partial_adapter`

Top gaps:
- Deepen reflection, DDL compilation, and Alembic-facing behavior.
- Add end-to-end ORM lifecycle and migration validation beyond deterministic dialect tests.
- Improve packaging, docs, and performance evidence for production adoption.

## Superset adapter

- Lane: `superset`
- Selected benchmark: `Superset PostgreSQL engine spec`
- Current state: `partial_adapter`

Top gaps:
- Expand engine-spec capability flags, time grains, and SQL Lab behavior to match first-party backends.
- Add end-to-end dataset discovery, async query, and dashboard validation.
- Harden package/install guidance for real Superset deployments.

## Swift driver

- Lane: `swift`
- Selected benchmark: `PostgresNIO`
- Current state: `partial`

Top gaps:
- Close live cancellation, suspend/resume, metadata, codec, and pool recovery gaps.
- Improve async/await and NIO lifecycle documentation and examples.
- Publish performance and reliability evidence expected in modern Swift server stacks.

## TypeORM adapter

- Lane: `typeorm`
- Selected benchmark: `TypeORM PostgreSQL driver`
- Current state: `partial_contract_only`

Top gaps:
- Move from deterministic scaffolding to a full datasource, schema sync, migration, and relation-loading surface.
- Close metadata reflection and query-builder behavior gaps.
- Add installation, packaging, and framework validation evidence.
