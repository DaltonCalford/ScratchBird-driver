# Driver Best-In-Class Competitive Closure Model

Date: 2026-04-03
Status: Draft - Implementation Ready

This specification supplements the existing lane specs by freezing the
benchmark target, competitive closure areas, and required release
evidence for every Beta 1 class driver, CLI, and adapter lane.

## Global Rules

- ScratchBird remains a native `SBWP v1.1` client and tooling stack.
- MGA/state-based recovery remains authoritative.
- Competitive parity means equal to or better than the selected
  benchmark in user-visible capability, diagnostics, packaging, and
  release evidence.
- Every lane must ship contract tests, conformance reports,
  compatibility matrices, performance numbers, known-gap lists, and
  stable packaging/release cadence evidence.

## Lane Summary

| Lane | Selected Benchmark | Mandatory Competitive Closure |
| --- | --- | --- |
| cpp | libpqxx | Require benchmark and allocator evidence in the release contract for the C++ lane.; Codify advanced prepared reuse, large result streaming, and TLS diagnostics examples. |
| cli | psql | Create a first-class CLI tools specification covering command surface, scripting, output modes, and copy/import/export semantics.; Make benchmarked script execution, formatting, and metadata tasks part of Beta 1 release evidence. |
| dart | postgres (Dart) | Promote live metadata, stream resume, and failure-path certification from optional to required release evidence.; Expand the Dart spec with benchmark-derived async ergonomics, metadata, and codec acceptance criteria. |
| dbeaver | DBeaver PostgreSQL extension | Create a dedicated DBeaver compatibility specification with plugin packaging, metadata, and UI behavior requirements.; Make update-site build/install validation and schema-tree goldens part of release evidence. |
| dotnet | Npgsql | Promote Npgsql-class diagnostics, pooling, and packaging expectations into the .NET spec supplement.; Require reproducible benchmark and compatibility matrices in the release evidence pack. |
| elixir | Postgrex | Expand the Ecto adapter spec with benchmark-driven stream, telemetry, and reconnect semantics.; Require end-to-end Ecto and direct-driver evidence in the release pack. |
| go | pgx | Promote pgx-class benchmarks, pool diagnostics, and advanced examples into the Go driver acceptance criteria. |
| hibernate | Hibernate PostgreSQLDialect | Create a Hibernate compatibility spec with dialect, ORM lifecycle, DDL, and migration acceptance gates.; Add live ORM bootstrap and schema-management evidence requirements. |
| jdbc | pgjdbc | Introduce a JDBC competitive-closure supplement that freezes pgjdbc-class metadata and release evidence expectations. |
| metabase | Metabase PostgreSQL driver | Expand the Metabase compatibility spec with benchmark-driven sync, feature-flag, and packaging requirements. |
| mojo | Composite (asyncpg + pgx + PostgresNIO) | Promote native transport cutover from checklist work to a hard competitive-closure requirement.; Define composite benchmark acceptance gates in the Mojo spec. |
| node | node-postgres | Add node-postgres-class release evidence and framework-integration examples to the Node spec. |
| odbc | Microsoft ODBC Driver for SQL Server | Use Microsoft ODBC behavior as the target bar but anchor implementation detail against psqlODBC.; Expand ODBC metadata and diagnostics requirements in the driver spec. |
| pascal | FireDAC | Freeze FireDAC-class ergonomics and ZeosLib-class implementation anchors into the Pascal lane supplement. |
| php | PDO_PGSQL | Make PDO-style ergonomics and packaging evidence part of the PHP closure criteria. |
| prisma | Prisma PostgreSQL connector | Create a Prisma compatibility spec with migration, introspection, and runtime acceptance criteria. |
| python | psycopg3 | Add psycopg3-class release evidence and advanced adaptation examples to the Python spec. |
| r | RPostgres | Promote RPostgres-class DBI ergonomics and metadata expectations into the R lane spec. |
| ruby | ruby-pg | Add ruby-pg-class release evidence and framework examples to the Ruby spec. |
| rust | tokio-postgres | Freeze tokio-postgres-class async and performance evidence into the Rust lane supplement. |
| sqlalchemy | SQLAlchemy PostgreSQL dialect | Create a SQLAlchemy compatibility specification with reflection, ORM, and migration acceptance gates. |
| superset | Superset PostgreSQL engine spec | Expand the Superset compatibility spec with benchmark-driven engine-spec, SQL Lab, and deployment requirements. |
| swift | PostgresNIO | Promote PostgresNIO-class async, pooling, and codec expectations into the Swift spec. |
| typeorm | TypeORM PostgreSQL driver | Create a TypeORM compatibility specification with datasource, migrations, relation, and query-builder acceptance gates. |

## Per-Lane Closure

## C/C++ driver

Selected benchmark: `libpqxx`

Current state:
Lane-local baseline mapping already marks all JDBC/.NET parity groups implemented. Competitive closure is about raising polish, packaging, and benchmark-backed proof rather than filling a baseline functional hole.

Mandatory closure items:
- Require benchmark and allocator evidence in the release contract for the C++ lane.
- Codify advanced prepared reuse, large result streaming, and TLS diagnostics examples.

## CLI tooling lane

Selected benchmark: `psql`

Current state:
The CLI lane is operational and conformance-capable, but lane-local mapping still marks TXN, META, TYPE, and RES as partial. Tooling parity has to be judged against operational CLIs, not just raw driver APIs.

Mandatory closure items:
- Create a first-class CLI tools specification covering command surface, scripting, output modes, and copy/import/export semantics.
- Make benchmarked script execution, formatting, and metadata tasks part of Beta 1 release evidence.

## Dart driver

Selected benchmark: `postgres (Dart)`

Current state:
Current audit still shows TXN, EXEC, META, TYPE, ERR, and RES gaps against the JDBC/.NET baseline. The lane already has a strong async foundation but lacks full competitive closure around metadata, live failure-path proof, and richer type coverage.

Mandatory closure items:
- Promote live metadata, stream resume, and failure-path certification from optional to required release evidence.
- Expand the Dart spec with benchmark-derived async ergonomics, metadata, and codec acceptance criteria.

## DBeaver integration

Selected benchmark: `DBeaver PostgreSQL extension`

Current state:
The current DBeaver work is a strong plugin scaffold plus a JDBC metadata compatibility switch, but not yet a full first-class DBeaver integration surface. The lane needs richer navigator, editor, packaging, and update-site closure to compete with first-party DBeaver extensions.

Mandatory closure items:
- Create a dedicated DBeaver compatibility specification with plugin packaging, metadata, and UI behavior requirements.
- Make update-site build/install validation and schema-tree goldens part of release evidence.

## .NET driver

Selected benchmark: `Npgsql`

Current state:
The lane is already at full baseline parity and should be treated as a flagship provider. Competitive closure is about exceeding Npgsql-level release quality, diagnostics, and ecosystem polish.

Mandatory closure items:
- Promote Npgsql-class diagnostics, pooling, and packaging expectations into the .NET spec supplement.
- Require reproducible benchmark and compatibility matrices in the release evidence pack.

## Elixir/Ecto driver

Selected benchmark: `Postgrex`

Current state:
The lane is close, but EXEC stream/paging proof and in-place reconnect behavior still lag the strongest Elixir drivers. The benchmark has to include both direct driver and Ecto adapter behavior.

Mandatory closure items:
- Expand the Ecto adapter spec with benchmark-driven stream, telemetry, and reconnect semantics.
- Require end-to-end Ecto and direct-driver evidence in the release pack.

## Go driver

Selected benchmark: `pgx`

Current state:
The Go lane is already baseline complete and should be pushed toward best-in-class ergonomics and performance proof. The core decision is to benchmark against pgx rather than a higher-level abstraction.

Mandatory closure items:
- Promote pgx-class benchmarks, pool diagnostics, and advanced examples into the Go driver acceptance criteria.

## Hibernate dialect

Selected benchmark: `Hibernate PostgreSQLDialect`

Current state:
The lane currently proves deterministic contract helpers, not a full first-class Hibernate runtime. Parity has to be judged against the strongest Hibernate dialects, especially PostgreSQL.

Mandatory closure items:
- Create a Hibernate compatibility spec with dialect, ORM lifecycle, DDL, and migration acceptance gates.
- Add live ORM bootstrap and schema-management evidence requirements.

## JDBC driver

Selected benchmark: `pgjdbc`

Current state:
The JDBC lane is already a flagship surface and should be judged against pgjdbc rather than minimal connector parity. Closure is now about metadata depth, release evidence, packaging, and ecosystem polish.

Mandatory closure items:
- Introduce a JDBC competitive-closure supplement that freezes pgjdbc-class metadata and release evidence expectations.

## Metabase adapter

Selected benchmark: `Metabase PostgreSQL driver`

Current state:
The Metabase plugin is thin and aligned to JDBC behavior, but it is not yet benchmarked against the strongest first-party Metabase database drivers. Schema sync, fingerprinting, and feature-flag behavior need first-class closure.

Mandatory closure items:
- Expand the Metabase compatibility spec with benchmark-driven sync, feature-flag, and packaging requirements.

## Mojo driver

Selected benchmark: `Composite (asyncpg + pgx + PostgresNIO)`

Current state:
Surface parity exists, but the lane still depends on a Python bridge and lacks full native SBWP transport closure. No single mature Mojo benchmark exists, so the benchmark has to be composite.

Mandatory closure items:
- Promote native transport cutover from checklist work to a hard competitive-closure requirement.
- Define composite benchmark acceptance gates in the Mojo spec.

## Node.js/TypeScript driver

Selected benchmark: `node-postgres`

Current state:
The Node lane is already strong and should now be pushed toward node-postgres-class polish and evidence. Competitive closure is mainly around performance proof, cancellation ergonomics, and ecosystem guidance.

Mandatory closure items:
- Add node-postgres-class release evidence and framework-integration examples to the Node spec.

## ODBC driver

Selected benchmark: `Microsoft ODBC Driver for SQL Server`

Current state:
The core ODBC lane is close, but metadata breadth and richer catalog surfaces still trail stronger ODBC implementations. The benchmark must account for a closed commercial leader with an open-source implementation anchor.

Mandatory closure items:
- Use Microsoft ODBC behavior as the target bar but anchor implementation detail against psqlODBC.
- Expand ODBC metadata and diagnostics requirements in the driver spec.

## Pascal/Delphi driver

Selected benchmark: `FireDAC`

Current state:
The lane is baseline complete, but the commercial FireDAC bar is still higher on IDE/packaging polish. Competitive closure must use an open-source anchor where the commercial benchmark is not inspectable.

Mandatory closure items:
- Freeze FireDAC-class ergonomics and ZeosLib-class implementation anchors into the Pascal lane supplement.

## PHP driver

Selected benchmark: `PDO_PGSQL`

Current state:
The PHP lane is functionally strong and should be driven toward PDO-grade polish and ecosystem clarity. The competitive target is ergonomics and release quality, not just baseline query support.

Mandatory closure items:
- Make PDO-style ergonomics and packaging evidence part of the PHP closure criteria.

## Prisma adapter

Selected benchmark: `Prisma PostgreSQL connector`

Current state:
The current lane is a deterministic scaffold, not yet a full provider runtime. Competitive closure has to be measured against official Prisma connectors, especially PostgreSQL.

Mandatory closure items:
- Create a Prisma compatibility spec with migration, introspection, and runtime acceptance criteria.

## Python driver

Selected benchmark: `psycopg3`

Current state:
The Python lane is already strong and should be compared to psycopg3 rather than only baseline DB-API compliance. Closure is about packaging, async posture, docs, and benchmark evidence.

Mandatory closure items:
- Add psycopg3-class release evidence and advanced adaptation examples to the Python spec.

## R driver

Selected benchmark: `RPostgres`

Current state:
Connection/auth coverage and richer metadata parity are still incomplete for the R lane. The target benchmark is the strongest DBI-native driver, not just any working wrapper.

Mandatory closure items:
- Promote RPostgres-class DBI ergonomics and metadata expectations into the R lane spec.

## Ruby driver

Selected benchmark: `ruby-pg`

Current state:
The Ruby lane is functionally strong; closure is about polish, release proof, and Rails-facing usability. The benchmark should stay on the direct `pg` gem rather than generic wrappers.

Mandatory closure items:
- Add ruby-pg-class release evidence and framework examples to the Ruby spec.

## Rust driver

Selected benchmark: `tokio-postgres`

Current state:
The Rust lane is already strong, but it still needs benchmark-backed proof and ecosystem integration closure. The benchmark should stay on direct async drivers, not just higher-level wrappers.

Mandatory closure items:
- Freeze tokio-postgres-class async and performance evidence into the Rust lane supplement.

## SQLAlchemy dialect

Selected benchmark: `SQLAlchemy PostgreSQL dialect`

Current state:
The dialect already reflects core metadata, but it is not yet benchmarked against the strongest first-party SQLAlchemy dialects. Alembic, ORM lifecycle, reflection depth, and DDL behavior remain the main closure areas.

Mandatory closure items:
- Create a SQLAlchemy compatibility specification with reflection, ORM, and migration acceptance gates.

## Superset adapter

Selected benchmark: `Superset PostgreSQL engine spec`

Current state:
The Superset package exists, but it is still closer to a good custom backend than a benchmarked first-class engine spec. Competitive closure has to cover SQL Lab, engine-spec feature flags, dataset discovery, and packaging.

Mandatory closure items:
- Expand the Superset compatibility spec with benchmark-driven engine-spec, SQL Lab, and deployment requirements.

## Swift driver

Selected benchmark: `PostgresNIO`

Current state:
The Swift lane still trails on live cancellation, portal resume, metadata breadth, advanced codecs, and pool fault recovery. The benchmark should be a direct Swift async/NIO relational driver, not a wrapper.

Mandatory closure items:
- Promote PostgresNIO-class async, pooling, and codec expectations into the Swift spec.

## TypeORM adapter

Selected benchmark: `TypeORM PostgreSQL driver`

Current state:
The current TypeORM lane is a deterministic contract helper set, not yet a production-grade adapter. Parity has to be judged against the official PostgreSQL TypeORM behavior, especially schema sync and migrations.

Mandatory closure items:
- Create a TypeORM compatibility specification with datasource, migrations, relation, and query-builder acceptance gates.
