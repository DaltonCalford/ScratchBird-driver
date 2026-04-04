#!/usr/bin/env python3
from __future__ import annotations

import csv
import datetime as dt
import html
import os
import pathlib
import re
import subprocess
import textwrap
import urllib.error
import urllib.parse
import urllib.request


ROOT = pathlib.Path("/home/dcalford/CliWork/ScratchBird-driver")
TODAY = "2026-04-03"
RESEARCH_ROOT = ROOT / "docs/reference/best_in_class_driver_research_2026-04-03"
AUDIT_ROOT = ROOT / "docs/audit/best_in_class_driver_gaps_2026-04-03"
SPEC_ROOT = ROOT / "docs/specifications"
APP_REF_ROOT = ROOT / "docs/application-reference"
API_REF_ROOT = ROOT / "docs/api-reference"
GETTING_STARTED_ROOT = ROOT / "docs/getting-started"


CATEGORY_ORDER = [
    ("connection_config", "Connection/config surface"),
    ("auth_tls", "Auth/TLS/secrets"),
    ("bootstrap_protocol", "Protocol/bootstrap/connect"),
    ("transaction_model", "Transactions/savepoints"),
    ("execution_lifecycle", "Prepared/batching/generated keys/callable or equivalent"),
    ("result_handling", "Results/streaming/paging/cancellation"),
    ("metadata_reflection", "Metadata/schema discovery/reflection"),
    ("type_fidelity", "Type encode/decode and wrappers"),
    ("error_surface", "Error surfaces and diagnostics"),
    ("pooling_resilience", "Pooling/resilience/reconnect/cleanup"),
    ("observability", "Observability/diagnostics"),
    ("packaging_release", "Package layout/release artifacts/cadence"),
    ("performance", "Performance and benchmark evidence"),
    ("ecosystem_fit", "Language/tool/application ecosystem expectations"),
]

WEIGHTS = [
    ("API completeness and standards conformance", 20),
    ("Transaction and error semantics correctness", 15),
    ("Metadata and tooling compatibility depth", 10),
    ("Type fidelity and advanced type support", 10),
    ("Performance and batching/streaming behavior", 15),
    ("Security/auth/TLS posture", 10),
    ("Pooling/resilience/recovery behavior", 10),
    ("Documentation/release quality", 5),
    ("Ecosystem adoption and maintenance health", 5),
]


PROFILE_MAPS = {
    "full_driver": {
        "connection_config": "at_parity",
        "auth_tls": "at_parity",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "at_parity",
        "execution_lifecycle": "at_parity",
        "result_handling": "at_parity",
        "metadata_reflection": "at_parity",
        "type_fidelity": "at_parity",
        "error_surface": "at_parity",
        "pooling_resilience": "at_parity",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "partial_dart": {
        "connection_config": "at_parity",
        "auth_tls": "partial_gap",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "partial_gap",
        "execution_lifecycle": "partial_gap",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "partial_gap",
        "error_surface": "partial_gap",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "partial_elixir": {
        "connection_config": "at_parity",
        "auth_tls": "at_parity",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "at_parity",
        "execution_lifecycle": "partial_gap",
        "result_handling": "partial_gap",
        "metadata_reflection": "at_parity",
        "type_fidelity": "at_parity",
        "error_surface": "at_parity",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "partial_odbc": {
        "connection_config": "at_parity",
        "auth_tls": "at_parity",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "at_parity",
        "execution_lifecycle": "at_parity",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "at_parity",
        "error_surface": "at_parity",
        "pooling_resilience": "at_parity",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "partial_r": {
        "connection_config": "partial_gap",
        "auth_tls": "partial_gap",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "at_parity",
        "execution_lifecycle": "at_parity",
        "result_handling": "at_parity",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "at_parity",
        "error_surface": "at_parity",
        "pooling_resilience": "at_parity",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "partial_swift": {
        "connection_config": "at_parity",
        "auth_tls": "partial_gap",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "at_parity",
        "execution_lifecycle": "partial_gap",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "partial_gap",
        "error_surface": "partial_gap",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "hybrid_mojo": {
        "connection_config": "partial_gap",
        "auth_tls": "partial_gap",
        "bootstrap_protocol": "partial_gap",
        "transaction_model": "partial_gap",
        "execution_lifecycle": "partial_gap",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "partial_gap",
        "error_surface": "partial_gap",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "cli_tooling": {
        "connection_config": "at_parity",
        "auth_tls": "partial_gap",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "partial_gap",
        "execution_lifecycle": "at_parity",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "partial_gap",
        "error_surface": "at_parity",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "adapter": {
        "connection_config": "at_parity",
        "auth_tls": "at_parity",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "partial_gap",
        "execution_lifecycle": "partial_gap",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "partial_gap",
        "error_surface": "partial_gap",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "partial_gap",
    },
    "adapter_contract": {
        "connection_config": "at_parity",
        "auth_tls": "at_parity",
        "bootstrap_protocol": "at_parity",
        "transaction_model": "partial_gap",
        "execution_lifecycle": "partial_gap",
        "result_handling": "partial_gap",
        "metadata_reflection": "partial_gap",
        "type_fidelity": "partial_gap",
        "error_surface": "partial_gap",
        "pooling_resilience": "partial_gap",
        "observability": "partial_gap",
        "packaging_release": "partial_gap",
        "performance": "partial_gap",
        "ecosystem_fit": "full_gap",
    },
}


LANES = [
    {
        "key": "cpp",
        "display": "C/C++ driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "Lane-local baseline mapping already marks all JDBC/.NET parity groups implemented.",
            "Competitive closure is about raising polish, packaging, and benchmark-backed proof rather than filling a baseline functional hole.",
        ],
        "selected": "libpqxx",
        "candidates": ["libpqxx", "SOCI", "nanodbc"],
        "selected_reason": "libpqxx remains the strongest open direct relational C++ benchmark for transactional correctness, typed result handling, prepared execution, and mature operational documentation without hiding too much behind framework abstraction.",
        "sources": [
            ("selected_docs", "libpqxx docs", "https://libpqxx.readthedocs.io/stable/"),
            ("selected_repo", "libpqxx repo", "https://github.com/jtv/libpqxx"),
            ("candidate_repo", "SOCI repo", "https://github.com/SOCI/soci"),
            ("candidate_docs", "nanodbc docs", "https://nanodbc.github.io/nanodbc/"),
        ],
        "gaps": [
            "Add benchmark-backed performance and memory-footprint evidence comparable to libpqxx’s mature deployment posture.",
            "Tighten diagnostic and tracing documentation so operational debugging is as easy as the incumbent C++ stack.",
            "Expand package/distribution guidance for Linux, Windows, and ABI-safe consumption.",
        ],
        "spec_actions": [
            "Require benchmark and allocator evidence in the release contract for the C++ lane.",
            "Codify advanced prepared reuse, large result streaming, and TLS diagnostics examples.",
        ],
    },
    {
        "key": "cli",
        "display": "CLI tooling lane",
        "profile": "cli_tooling",
        "current_state": "partial_tooling",
        "current_summary": [
            "The CLI lane is operational and conformance-capable, but lane-local mapping still marks TXN, META, TYPE, and RES as partial.",
            "Tooling parity has to be judged against operational CLIs, not just raw driver APIs.",
        ],
        "selected": "psql",
        "candidates": ["psql", "usql", "mycli"],
        "selected_reason": "psql is still the best-in-class benchmark for serious database CLI workflows because it combines scripting, introspection, copy/import/export, transaction control, formatting, and battle-tested automation semantics in one tool.",
        "sources": [
            ("selected_docs", "psql docs", "https://www.postgresql.org/docs/current/app-psql.html"),
            ("selected_repo", "PostgreSQL repo", "https://github.com/postgres/postgres"),
            ("candidate_repo", "usql repo", "https://github.com/xo/usql"),
            ("candidate_docs", "mycli project", "https://www.mycli.net/"),
            ("candidate_repo", "mycli repo", "https://github.com/dbcli/mycli"),
        ],
        "gaps": [
            "Close metadata and schema-browser coverage so CLI tooling can match psql-style introspection depth.",
            "Expand scripting/import/export and output-format ergonomics to compete with psql and usql automation flows.",
            "Improve platform packaging and runtime portability beyond Linux-first coverage.",
        ],
        "spec_actions": [
            "Create a first-class CLI tools specification covering command surface, scripting, output modes, and copy/import/export semantics.",
            "Make benchmarked script execution, formatting, and metadata tasks part of Beta 1 release evidence.",
        ],
    },
    {
        "key": "dart",
        "display": "Dart driver",
        "profile": "partial_dart",
        "current_state": "partial",
        "current_summary": [
            "Current audit still shows TXN, EXEC, META, TYPE, ERR, and RES gaps against the JDBC/.NET baseline.",
            "The lane already has a strong async foundation but lacks full competitive closure around metadata, live failure-path proof, and richer type coverage.",
        ],
        "selected": "postgres (Dart)",
        "candidates": ["postgres (Dart)", "mysql1", "sqlite3"],
        "selected_reason": "The Dart `postgres` package remains the best direct benchmark because it is the most feature-rich, idiomatic async relational client in the Dart ecosystem with mature statement, transaction, and stream handling.",
        "sources": [
            ("selected_docs", "pub.dev postgres", "https://pub.dev/packages/postgres"),
            ("selected_repo", "postgresql-dart repo", "https://github.com/isoos/postgresql-dart"),
            ("candidate_docs", "mysql1 package", "https://pub.dev/packages/mysql1"),
            ("candidate_docs", "sqlite3 package", "https://pub.dev/packages/sqlite3"),
        ],
        "gaps": [
            "Complete transaction failure-path, suspend/resume, and resilience proof to the level expected by the leading Dart driver.",
            "Fill metadata restriction and DDL payload coverage gaps for tooling ecosystems.",
            "Broaden live complex-type codecs and runtime SQLSTATE/error propagation proof.",
        ],
        "spec_actions": [
            "Promote live metadata, stream resume, and failure-path certification from optional to required release evidence.",
            "Expand the Dart spec with benchmark-derived async ergonomics, metadata, and codec acceptance criteria.",
        ],
    },
    {
        "key": "dbeaver",
        "display": "DBeaver integration",
        "profile": "adapter",
        "current_state": "partial_plugin",
        "current_summary": [
            "The current DBeaver work is a strong plugin scaffold plus a JDBC metadata compatibility switch, but not yet a full first-class DBeaver integration surface.",
            "The lane needs richer navigator, editor, packaging, and update-site closure to compete with first-party DBeaver extensions.",
        ],
        "selected": "DBeaver PostgreSQL extension",
        "candidates": ["DBeaver PostgreSQL extension", "DBeaver MySQL extension", "DBeaver SQL Server extension"],
        "selected_reason": "The PostgreSQL extension is the best benchmark because it exercises the broadest metadata tree, DDL tooling, and general-purpose relational workflows in DBeaver’s own plugin architecture.",
        "sources": [
            ("selected_docs", "DBeaver driver docs", "https://dbeaver.com/docs/dbeaver/Database-drivers/"),
            ("selected_repo", "DBeaver PostgreSQL plugin", "https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.postgresql"),
            ("candidate_repo", "DBeaver MySQL plugin", "https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.mysql"),
            ("candidate_repo", "DBeaver SQL Server plugin", "https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.mssql"),
        ],
        "gaps": [
            "Expand navigator and schema-tree behavior to match the first-party DBeaver extensions without resorting to manual toggles.",
            "Add explain/plan, DDL editor, and richer metadata view integration.",
            "Harden stock-install and update-site packaging/documentation for enterprise installs.",
        ],
        "spec_actions": [
            "Create a dedicated DBeaver compatibility specification with plugin packaging, metadata, and UI behavior requirements.",
            "Make update-site build/install validation and schema-tree goldens part of release evidence.",
        ],
    },
    {
        "key": "dotnet",
        "display": ".NET driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The lane is already at full baseline parity and should be treated as a flagship provider.",
            "Competitive closure is about exceeding Npgsql-level release quality, diagnostics, and ecosystem polish.",
        ],
        "selected": "Npgsql",
        "candidates": ["Npgsql", "Microsoft.Data.SqlClient", "MySqlConnector"],
        "selected_reason": "Npgsql is the strongest open ADO.NET benchmark because it combines provider completeness, excellent performance, broad tooling support, and mature operational documentation.",
        "sources": [
            ("selected_docs", "Npgsql docs", "https://www.npgsql.org/doc/index.html"),
            ("selected_repo", "Npgsql repo", "https://github.com/npgsql/npgsql"),
            ("candidate_docs", "Microsoft.Data.SqlClient docs", "https://learn.microsoft.com/en-us/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace?view=sql-server-ver17"),
            ("candidate_repo", "MySqlConnector repo", "https://github.com/mysql-net/MySqlConnector"),
        ],
        "gaps": [
            "Publish benchmark and operational evidence at the same standard expected of top-tier ADO.NET providers.",
            "Tighten integration guidance for ORMs, diagnostics, and pooling scenarios.",
            "Surface advanced provider ergonomics and troubleshooting guidance more directly in docs.",
        ],
        "spec_actions": [
            "Promote Npgsql-class diagnostics, pooling, and packaging expectations into the .NET spec supplement.",
            "Require reproducible benchmark and compatibility matrices in the release evidence pack.",
        ],
    },
    {
        "key": "elixir",
        "display": "Elixir/Ecto driver",
        "profile": "partial_elixir",
        "current_state": "partial",
        "current_summary": [
            "The lane is close, but EXEC stream/paging proof and in-place reconnect behavior still lag the strongest Elixir drivers.",
            "The benchmark has to include both direct driver and Ecto adapter behavior.",
        ],
        "selected": "Postgrex",
        "candidates": ["Postgrex", "MyXQL", "Tds"],
        "selected_reason": "Postgrex remains the strongest direct Elixir benchmark because of its mature protocol handling, Ecto integration, telemetry surface, and proven transaction/query semantics.",
        "sources": [
            ("selected_docs", "Postgrex docs", "https://hexdocs.pm/postgrex/readme.html"),
            ("selected_repo", "Postgrex repo", "https://github.com/elixir-ecto/postgrex"),
            ("candidate_docs", "MyXQL docs", "https://hexdocs.pm/myxql/readme.html"),
            ("candidate_docs", "Tds docs", "https://hexdocs.pm/tds/readme.html"),
        ],
        "gaps": [
            "Expose standalone public stream/paging helpers and stronger deterministic stream proof.",
            "Close the remaining resilience gap so reconnect/recovery behavior is competitive with Postgrex operationally.",
            "Document telemetry and Ecto integration expectations as first-class contractual requirements.",
        ],
        "spec_actions": [
            "Expand the Ecto adapter spec with benchmark-driven stream, telemetry, and reconnect semantics.",
            "Require end-to-end Ecto and direct-driver evidence in the release pack.",
        ],
    },
    {
        "key": "go",
        "display": "Go driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The Go lane is already baseline complete and should be pushed toward best-in-class ergonomics and performance proof.",
            "The core decision is to benchmark against pgx rather than a higher-level abstraction.",
        ],
        "selected": "pgx",
        "candidates": ["pgx", "go-sql-driver/mysql", "go-mssqldb"],
        "selected_reason": "pgx is the strongest open benchmark for direct Go relational drivers because it balances raw performance, correctness, typed APIs, and database/sql compatibility.",
        "sources": [
            ("selected_docs", "pgx docs", "https://pkg.go.dev/github.com/jackc/pgx/v5"),
            ("selected_repo", "pgx repo", "https://github.com/jackc/pgx"),
            ("candidate_repo", "go-sql-driver/mysql repo", "https://github.com/go-sql-driver/mysql"),
            ("candidate_repo", "go-mssqldb repo", "https://github.com/microsoft/go-mssqldb"),
        ],
        "gaps": [
            "Strengthen benchmark-backed evidence for high-concurrency and large-result performance.",
            "Refine documentation around pooling, cancellation, and advanced codecs to exceed pgx usability.",
            "Broaden ecosystem guidance for ORMs and migration tools.",
        ],
        "spec_actions": [
            "Promote pgx-class benchmarks, pool diagnostics, and advanced examples into the Go driver acceptance criteria.",
        ],
    },
    {
        "key": "hibernate",
        "display": "Hibernate dialect",
        "profile": "adapter_contract",
        "current_state": "partial_contract_only",
        "current_summary": [
            "The lane currently proves deterministic contract helpers, not a full first-class Hibernate runtime.",
            "Parity has to be judged against the strongest Hibernate dialects, especially PostgreSQL.",
        ],
        "selected": "Hibernate PostgreSQLDialect",
        "candidates": ["Hibernate PostgreSQLDialect", "Hibernate SQLServerDialect", "Hibernate MySQLDialect"],
        "selected_reason": "The PostgreSQL dialect is the best benchmark because it exercises the widest practical range of Hibernate ORM behavior while staying closest to ScratchBird’s relational feature shape.",
        "sources": [
            ("selected_docs", "Hibernate dialect docs", "https://docs.jboss.org/hibernate/orm/current/dialect/dialect.html"),
            ("selected_repo", "Hibernate ORM repo", "https://github.com/hibernate/hibernate-orm"),
            ("candidate_docs", "Hibernate user guide", "https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html"),
        ],
        "gaps": [
            "Move from deterministic dialect helpers to full schema tooling, DDL generation, and entity lifecycle validation.",
            "Close pagination, locking, generated key, and type contribution gaps against the strongest PostgreSQL dialect behavior.",
            "Add migration and integration-test evidence instead of relying only on contract-unit coverage.",
        ],
        "spec_actions": [
            "Create a Hibernate compatibility spec with dialect, ORM lifecycle, DDL, and migration acceptance gates.",
            "Add live ORM bootstrap and schema-management evidence requirements.",
        ],
    },
    {
        "key": "jdbc",
        "display": "JDBC driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The JDBC lane is already a flagship surface and should be judged against pgjdbc rather than minimal connector parity.",
            "Closure is now about metadata depth, release evidence, packaging, and ecosystem polish.",
        ],
        "selected": "pgjdbc",
        "candidates": ["pgjdbc", "MySQL Connector/J", "Microsoft JDBC Driver for SQL Server"],
        "selected_reason": "pgjdbc remains the strongest open JDBC benchmark because of its DatabaseMetaData breadth, protocol maturity, batching and copy behavior, and extensive framework compatibility.",
        "sources": [
            ("selected_docs", "pgjdbc docs", "https://jdbc.postgresql.org/documentation/"),
            ("selected_repo", "pgjdbc repo", "https://github.com/pgjdbc/pgjdbc"),
            ("candidate_repo", "Connector/J repo", "https://github.com/mysql/mysql-connector-j"),
            ("candidate_docs", "Microsoft JDBC docs", "https://learn.microsoft.com/en-us/sql/connect/jdbc/overview-of-the-jdbc-driver?view=sql-server-ver17"),
            ("candidate_repo", "mssql-jdbc repo", "https://github.com/microsoft/mssql-jdbc"),
        ],
        "gaps": [
            "Benchmark and publish metadata breadth, large-object, batch, and performance evidence at pgjdbc quality.",
            "Tighten framework-facing guidance for Hibernate, Spring, BI tooling, and migration ecosystems.",
            "Raise packaging/release cadence documentation to the standard of major JDBC providers.",
        ],
        "spec_actions": [
            "Introduce a JDBC competitive-closure supplement that freezes pgjdbc-class metadata and release evidence expectations.",
        ],
    },
    {
        "key": "metabase",
        "display": "Metabase adapter",
        "profile": "adapter",
        "current_state": "partial_adapter",
        "current_summary": [
            "The Metabase plugin is thin and aligned to JDBC behavior, but it is not yet benchmarked against the strongest first-party Metabase database drivers.",
            "Schema sync, fingerprinting, and feature-flag behavior need first-class closure.",
        ],
        "selected": "Metabase PostgreSQL driver",
        "candidates": ["Metabase PostgreSQL driver", "Metabase MySQL driver", "Metabase SQL Server driver"],
        "selected_reason": "The PostgreSQL driver is the strongest benchmark because it exercises the richest combination of query builder, native SQL, sync, and field fingerprinting behavior in Metabase.",
        "sources": [
            ("selected_docs", "Metabase databases docs", "https://www.metabase.com/docs/latest/databases/start"),
            ("selected_repo", "Metabase repo", "https://github.com/metabase/metabase"),
            ("candidate_docs", "Metabase PostgreSQL docs", "https://www.metabase.com/docs/latest/databases/connections/postgresql"),
            ("candidate_docs", "Metabase MySQL docs", "https://www.metabase.com/docs/latest/databases/connections/mysql"),
            ("candidate_docs", "Metabase SQL Server docs", "https://www.metabase.com/docs/latest/databases/connections/sql-server"),
        ],
        "gaps": [
            "Close schema sync and field fingerprinting depth gaps so Metabase behavior matches the leading first-party plugins.",
            "Harden capability flags, native query handling, and packaging/deployment guidance.",
            "Add full end-to-end plugin validation against modern Metabase runtimes.",
        ],
        "spec_actions": [
            "Expand the Metabase compatibility spec with benchmark-driven sync, feature-flag, and packaging requirements.",
        ],
    },
    {
        "key": "mojo",
        "display": "Mojo driver",
        "profile": "hybrid_mojo",
        "current_state": "hybrid_native_gap",
        "current_summary": [
            "Surface parity exists, but the lane still depends on a Python bridge and lacks full native SBWP transport closure.",
            "No single mature Mojo benchmark exists, so the benchmark has to be composite.",
        ],
        "selected": "Composite (asyncpg + pgx + PostgresNIO)",
        "candidates": ["Composite (asyncpg + pgx + PostgresNIO)", "asyncpg", "pgx"],
        "selected_reason": "A composite benchmark is the only defensible choice because the Mojo ecosystem does not yet have a mature direct relational driver; the target bar must be assembled from the best direct async drivers in adjacent ecosystems.",
        "sources": [
            ("selected_docs", "asyncpg docs", "https://magicstack.github.io/asyncpg/current/"),
            ("selected_repo", "asyncpg repo", "https://github.com/MagicStack/asyncpg"),
            ("candidate_docs", "pgx docs", "https://pkg.go.dev/github.com/jackc/pgx/v5"),
            ("candidate_repo", "PostgresNIO repo", "https://github.com/vapor/postgres-nio"),
        ],
        "gaps": [
            "Replace the Python bridge with a native transport/runtime path.",
            "Close native TLS, streaming, type-wrapper, and packaging gaps using the composite benchmark as the target bar.",
            "Add first-class examples and performance proof once the transport cutover lands.",
        ],
        "spec_actions": [
            "Promote native transport cutover from checklist work to a hard competitive-closure requirement.",
            "Define composite benchmark acceptance gates in the Mojo spec.",
        ],
    },
    {
        "key": "node",
        "display": "Node.js/TypeScript driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The Node lane is already strong and should now be pushed toward node-postgres-class polish and evidence.",
            "Competitive closure is mainly around performance proof, cancellation ergonomics, and ecosystem guidance.",
        ],
        "selected": "node-postgres",
        "candidates": ["node-postgres", "mysql2", "tedious"],
        "selected_reason": "node-postgres is still the best direct Node benchmark because of its mature pooling, prepared statements, cursor/stream support, and enormous ecosystem adoption.",
        "sources": [
            ("selected_docs", "node-postgres docs", "https://node-postgres.com/"),
            ("selected_repo", "node-postgres repo", "https://github.com/brianc/node-postgres"),
            ("candidate_docs", "mysql2 docs", "https://sidorares.github.io/node-mysql2/docs"),
            ("candidate_repo", "tedious repo", "https://github.com/tediousjs/tedious"),
        ],
        "gaps": [
            "Publish benchmark and operational evidence at the level expected from top Node drivers.",
            "Refine cancellation, cursor, and pool troubleshooting guidance for framework integrators.",
            "Broaden examples for TypeScript-heavy application patterns.",
        ],
        "spec_actions": [
            "Add node-postgres-class release evidence and framework-integration examples to the Node spec.",
        ],
    },
    {
        "key": "odbc",
        "display": "ODBC driver",
        "profile": "partial_odbc",
        "current_state": "partial",
        "current_summary": [
            "The core ODBC lane is close, but metadata breadth and richer catalog surfaces still trail stronger ODBC implementations.",
            "The benchmark must account for a closed commercial leader with an open-source implementation anchor.",
        ],
        "selected": "Microsoft ODBC Driver for SQL Server",
        "candidates": ["Microsoft ODBC Driver for SQL Server", "psqlODBC", "MySQL Connector/ODBC"],
        "selected_reason": "The Microsoft driver is still the de facto best-in-class ODBC benchmark for metadata, diagnostics, packaging, and platform support, but ScratchBird needs an open-source anchor from psqlODBC for implementation structure.",
        "sources": [
            ("selected_docs", "Microsoft ODBC docs", "https://learn.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server"),
            ("anchor_docs", "psqlODBC project", "https://odbc.postgresql.org/"),
            ("anchor_repo", "psqlODBC repo", "https://github.com/postgresql-interfaces/psqlodbc"),
            ("candidate_repo", "MySQL Connector/ODBC repo", "https://github.com/mysql/mysql-connector-odbc"),
        ],
        "gaps": [
            "Close full-family metadata and catalog-surface gaps against the strongest ODBC drivers.",
            "Broaden descriptor, cursor, and diagnostics coverage where the commercial benchmark is stronger.",
            "Improve platform packaging and installation guidance across Windows and Linux.",
        ],
        "spec_actions": [
            "Use Microsoft ODBC behavior as the target bar but anchor implementation detail against psqlODBC.",
            "Expand ODBC metadata and diagnostics requirements in the driver spec.",
        ],
    },
    {
        "key": "pascal",
        "display": "Pascal/Delphi driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The lane is baseline complete, but the commercial FireDAC bar is still higher on IDE/packaging polish.",
            "Competitive closure must use an open-source anchor where the commercial benchmark is not inspectable.",
        ],
        "selected": "FireDAC",
        "candidates": ["FireDAC", "ZeosLib", "FreePascal SQLDB"],
        "selected_reason": "FireDAC remains the strongest Pascal/Delphi benchmark because of its dataset integration, IDE fit, and broad feature surface, while ZeosLib is the practical open-source anchor for implementation comparison.",
        "sources": [
            ("selected_docs", "FireDAC docs", "https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Connect_to_PostgreSQL_(FireDAC)"),
            ("anchor_docs", "ZeosLib mirror", "https://github.com/frones/ZeosLib"),
            ("candidate_docs", "FreePascal FCL docs", "https://docs.freepascal.org/docs-html/fcl/"),
        ],
        "gaps": [
            "Raise packaging, IDE, and operational guidance to the standard expected by Delphi developers.",
            "Add richer dataset- and component-oriented examples and validation.",
            "Publish performance and release evidence to support commercial-grade evaluation.",
        ],
        "spec_actions": [
            "Freeze FireDAC-class ergonomics and ZeosLib-class implementation anchors into the Pascal lane supplement.",
        ],
    },
    {
        "key": "php",
        "display": "PHP driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The PHP lane is functionally strong and should be driven toward PDO-grade polish and ecosystem clarity.",
            "The competitive target is ergonomics and release quality, not just baseline query support.",
        ],
        "selected": "PDO_PGSQL",
        "candidates": ["PDO_PGSQL", "ext-pgsql", "amphp/postgres"],
        "selected_reason": "PDO_PGSQL is the best benchmark because it sets the expectation for mainstream PHP relational ergonomics, parameter binding, and framework compatibility.",
        "sources": [
            ("selected_docs", "PDO_PGSQL source", "https://github.com/php/php-src/tree/master/ext/pdo_pgsql"),
            ("selected_repo", "PHP source repo", "https://github.com/php/php-src"),
            ("candidate_docs", "ext-pgsql source", "https://github.com/php/php-src/tree/master/ext/pgsql"),
            ("candidate_repo", "amphp/postgres repo", "https://github.com/amphp/postgres"),
        ],
        "gaps": [
            "Expand packaging and framework guidance to match the clarity of mainstream PHP database stacks.",
            "Publish benchmark and memory/streaming evidence for long-running app workloads.",
            "Add more typed error and parameter-binding examples for PDO-style adopters.",
        ],
        "spec_actions": [
            "Make PDO-style ergonomics and packaging evidence part of the PHP closure criteria.",
        ],
    },
    {
        "key": "prisma",
        "display": "Prisma adapter",
        "profile": "adapter_contract",
        "current_state": "partial_contract_only",
        "current_summary": [
            "The current lane is a deterministic scaffold, not yet a full provider runtime.",
            "Competitive closure has to be measured against official Prisma connectors, especially PostgreSQL.",
        ],
        "selected": "Prisma PostgreSQL connector",
        "candidates": ["Prisma PostgreSQL connector", "Prisma MySQL connector", "Prisma SQL Server connector"],
        "selected_reason": "The PostgreSQL connector is the strongest Prisma benchmark because it receives the most complete introspection, migration, and runtime coverage in the Prisma ecosystem.",
        "sources": [
            ("selected_docs", "Prisma PostgreSQL docs", "https://www.prisma.io/docs/orm/overview/databases/postgresql"),
            ("selected_repo", "Prisma repo", "https://github.com/prisma/prisma"),
            ("candidate_docs", "Prisma MySQL docs", "https://www.prisma.io/docs/orm/overview/databases/mysql"),
            ("candidate_docs", "Prisma SQL Server docs", "https://www.prisma.io/docs/orm/overview/databases/sql-server"),
        ],
        "gaps": [
            "Move from deterministic helper scaffolding to a full provider-quality introspection and migration surface.",
            "Close datasource validation, schema reflection, and transaction/runtime behavior gaps.",
            "Add packaging and framework-facing integration guidance for Prisma users.",
        ],
        "spec_actions": [
            "Create a Prisma compatibility spec with migration, introspection, and runtime acceptance criteria.",
        ],
    },
    {
        "key": "python",
        "display": "Python driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The Python lane is already strong and should be compared to psycopg3 rather than only baseline DB-API compliance.",
            "Closure is about packaging, async posture, docs, and benchmark evidence.",
        ],
        "selected": "psycopg3",
        "candidates": ["psycopg3", "asyncpg", "mysqlclient"],
        "selected_reason": "psycopg3 is still the best benchmark because it combines DB-API correctness, advanced type adaptation, async support, and mature operational documentation.",
        "sources": [
            ("selected_docs", "psycopg3 docs", "https://www.psycopg.org/psycopg3/docs/"),
            ("selected_repo", "psycopg repo", "https://github.com/psycopg/psycopg"),
            ("candidate_docs", "asyncpg docs", "https://magicstack.github.io/asyncpg/current/"),
            ("candidate_repo", "mysqlclient repo", "https://github.com/PyMySQL/mysqlclient"),
        ],
        "gaps": [
            "Publish benchmark and async/runtime evidence at the standard expected by top Python drivers.",
            "Broaden packaging and framework integration guidance beyond baseline usage.",
            "Strengthen documentation for advanced codecs, cancellation, and copy/stream patterns.",
        ],
        "spec_actions": [
            "Add psycopg3-class release evidence and advanced adaptation examples to the Python spec.",
        ],
    },
    {
        "key": "r",
        "display": "R driver",
        "profile": "partial_r",
        "current_state": "partial",
        "current_summary": [
            "Connection/auth coverage and richer metadata parity are still incomplete for the R lane.",
            "The target benchmark is the strongest DBI-native driver, not just any working wrapper.",
        ],
        "selected": "RPostgres",
        "candidates": ["RPostgres", "RMariaDB", "odbc"],
        "selected_reason": "RPostgres is the strongest benchmark because it is the most mature DBI-native relational driver with strong data frame integration and operational adoption.",
        "sources": [
            ("selected_docs", "RPostgres docs", "https://rpostgres.r-dbi.org/"),
            ("selected_repo", "RPostgres repo", "https://github.com/r-dbi/RPostgres"),
            ("candidate_docs", "RMariaDB docs", "https://rmariadb.r-dbi.org/"),
            ("candidate_docs", "R odbc docs", "https://odbc.r-dbi.org/"),
        ],
        "gaps": [
            "Close connection/auth environment-gated proof and stronger runtime examples.",
            "Expand metadata, DDL-editor, and privilege-related introspection parity.",
            "Improve packaging, reproducibility, and data-frame shaping evidence for R users.",
        ],
        "spec_actions": [
            "Promote RPostgres-class DBI ergonomics and metadata expectations into the R lane spec.",
        ],
    },
    {
        "key": "ruby",
        "display": "Ruby driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The Ruby lane is functionally strong; closure is about polish, release proof, and Rails-facing usability.",
            "The benchmark should stay on the direct `pg` gem rather than generic wrappers.",
        ],
        "selected": "ruby-pg",
        "candidates": ["ruby-pg", "mysql2", "tiny_tds"],
        "selected_reason": "ruby-pg is the strongest benchmark because it is the canonical direct relational client in the Ruby ecosystem, with mature prepared statement, copy, and transaction behavior.",
        "sources": [
            ("selected_repo", "ruby-pg repo", "https://github.com/ged/ruby-pg"),
            ("candidate_repo", "mysql2 repo", "https://github.com/brianmario/mysql2"),
            ("candidate_repo", "tiny_tds repo", "https://github.com/rails-sqlserver/tiny_tds"),
        ],
        "gaps": [
            "Publish benchmark, packaging, and Rails-oriented guidance at the standard expected by the top Ruby database gems.",
            "Broaden documentation around encoding, copy/streaming, and operational diagnostics.",
        ],
        "spec_actions": [
            "Add ruby-pg-class release evidence and framework examples to the Ruby spec.",
        ],
    },
    {
        "key": "rust",
        "display": "Rust driver",
        "profile": "full_driver",
        "current_state": "full_parity",
        "current_summary": [
            "The Rust lane is already strong, but it still needs benchmark-backed proof and ecosystem integration closure.",
            "The benchmark should stay on direct async drivers, not just higher-level wrappers.",
        ],
        "selected": "tokio-postgres",
        "candidates": ["tokio-postgres", "sqlx", "mysql_async"],
        "selected_reason": "tokio-postgres is the strongest direct-driver benchmark because it is a low-level, high-quality async relational client with broad ecosystem adoption and robust type/transaction semantics.",
        "sources": [
            ("selected_docs", "tokio-postgres docs", "https://docs.rs/tokio-postgres/latest/tokio_postgres/"),
            ("selected_repo", "rust-postgres repo", "https://github.com/sfackler/rust-postgres"),
            ("candidate_docs", "sqlx docs", "https://docs.rs/sqlx/latest/sqlx/"),
            ("candidate_docs", "mysql_async docs", "https://docs.rs/mysql_async/latest/mysql_async/"),
        ],
        "gaps": [
            "Publish benchmark and concurrency evidence at the standard of the leading Rust async drivers.",
            "Expand framework, migration, and ecosystem integration guidance.",
            "Broaden observability and troubleshooting examples for async workloads.",
        ],
        "spec_actions": [
            "Freeze tokio-postgres-class async and performance evidence into the Rust lane supplement.",
        ],
    },
    {
        "key": "sqlalchemy",
        "display": "SQLAlchemy dialect",
        "profile": "adapter",
        "current_state": "partial_adapter",
        "current_summary": [
            "The dialect already reflects core metadata, but it is not yet benchmarked against the strongest first-party SQLAlchemy dialects.",
            "Alembic, ORM lifecycle, reflection depth, and DDL behavior remain the main closure areas.",
        ],
        "selected": "SQLAlchemy PostgreSQL dialect",
        "candidates": ["SQLAlchemy PostgreSQL dialect", "SQLAlchemy MySQL dialect", "SQLAlchemy SQL Server dialect"],
        "selected_reason": "The PostgreSQL dialect is the strongest benchmark because it exercises the richest reflection, DDL, ORM, and Alembic integration behavior in the mainstream SQLAlchemy ecosystem.",
        "sources": [
            ("selected_docs", "SQLAlchemy PostgreSQL dialect docs", "https://docs.sqlalchemy.org/en/20/dialects/postgresql.html"),
            ("selected_repo", "SQLAlchemy repo", "https://github.com/sqlalchemy/sqlalchemy"),
            ("candidate_docs", "SQLAlchemy MySQL dialect docs", "https://docs.sqlalchemy.org/en/20/dialects/mysql.html"),
            ("candidate_docs", "SQLAlchemy MSSQL dialect docs", "https://docs.sqlalchemy.org/en/20/dialects/mssql.html"),
        ],
        "gaps": [
            "Deepen reflection, DDL compilation, and Alembic-facing behavior.",
            "Add end-to-end ORM lifecycle and migration validation beyond deterministic dialect tests.",
            "Improve packaging, docs, and performance evidence for production adoption.",
        ],
        "spec_actions": [
            "Create a SQLAlchemy compatibility specification with reflection, ORM, and migration acceptance gates.",
        ],
    },
    {
        "key": "superset",
        "display": "Superset adapter",
        "profile": "adapter",
        "current_state": "partial_adapter",
        "current_summary": [
            "The Superset package exists, but it is still closer to a good custom backend than a benchmarked first-class engine spec.",
            "Competitive closure has to cover SQL Lab, engine-spec feature flags, dataset discovery, and packaging.",
        ],
        "selected": "Superset PostgreSQL engine spec",
        "candidates": ["Superset PostgreSQL engine spec", "Superset MySQL engine spec", "Superset Trino engine spec"],
        "selected_reason": "The PostgreSQL engine spec is the strongest benchmark because it is the richest broadly used SQL backend in Superset and exercises reflection, SQL Lab, time grains, and metadata behavior deeply.",
        "sources": [
            ("selected_docs", "Superset DB engine specs", "https://github.com/apache/superset/tree/master/superset/db_engine_specs"),
            ("selected_repo", "Superset repo", "https://github.com/apache/superset"),
            ("candidate_repo", "Superset repo", "https://github.com/apache/superset"),
        ],
        "gaps": [
            "Expand engine-spec capability flags, time grains, and SQL Lab behavior to match first-party backends.",
            "Add end-to-end dataset discovery, async query, and dashboard validation.",
            "Harden package/install guidance for real Superset deployments.",
        ],
        "spec_actions": [
            "Expand the Superset compatibility spec with benchmark-driven engine-spec, SQL Lab, and deployment requirements.",
        ],
    },
    {
        "key": "swift",
        "display": "Swift driver",
        "profile": "partial_swift",
        "current_state": "partial",
        "current_summary": [
            "The Swift lane still trails on live cancellation, portal resume, metadata breadth, advanced codecs, and pool fault recovery.",
            "The benchmark should be a direct Swift async/NIO relational driver, not a wrapper.",
        ],
        "selected": "PostgresNIO",
        "candidates": ["PostgresNIO", "PostgresKit", "MySQLNIO"],
        "selected_reason": "PostgresNIO is the strongest benchmark because it is a mature direct Swift/NIO relational client with strong async behavior, pooling patterns, and ecosystem adoption.",
        "sources": [
            ("selected_repo", "PostgresNIO repo", "https://github.com/vapor/postgres-nio"),
            ("candidate_repo", "PostgresKit repo", "https://github.com/vapor/postgres-kit"),
            ("candidate_repo", "MySQLNIO repo", "https://github.com/vapor/mysql-nio"),
        ],
        "gaps": [
            "Close live cancellation, suspend/resume, metadata, codec, and pool recovery gaps.",
            "Improve async/await and NIO lifecycle documentation and examples.",
            "Publish performance and reliability evidence expected in modern Swift server stacks.",
        ],
        "spec_actions": [
            "Promote PostgresNIO-class async, pooling, and codec expectations into the Swift spec.",
        ],
    },
    {
        "key": "typeorm",
        "display": "TypeORM adapter",
        "profile": "adapter_contract",
        "current_state": "partial_contract_only",
        "current_summary": [
            "The current TypeORM lane is a deterministic contract helper set, not yet a production-grade adapter.",
            "Parity has to be judged against the official PostgreSQL TypeORM behavior, especially schema sync and migrations.",
        ],
        "selected": "TypeORM PostgreSQL driver",
        "candidates": ["TypeORM PostgreSQL driver", "TypeORM MySQL driver", "TypeORM SQL Server driver"],
        "selected_reason": "The PostgreSQL driver is the strongest TypeORM benchmark because it exercises the deepest range of TypeORM schema, migration, relation, and query-builder behavior in production use.",
        "sources": [
            ("selected_docs", "TypeORM PostgreSQL docs", "https://typeorm.io/docs/drivers/postgres/"),
            ("selected_repo", "TypeORM repo", "https://github.com/typeorm/typeorm"),
            ("candidate_docs", "TypeORM MySQL docs", "https://typeorm.io/docs/drivers/mysql/"),
            ("candidate_docs", "TypeORM SQL Server docs", "https://typeorm.io/docs/drivers/microsoft-sqlserver/"),
        ],
        "gaps": [
            "Move from deterministic scaffolding to a full datasource, schema sync, migration, and relation-loading surface.",
            "Close metadata reflection and query-builder behavior gaps.",
            "Add installation, packaging, and framework validation evidence.",
        ],
        "spec_actions": [
            "Create a TypeORM compatibility specification with datasource, migrations, relation, and query-builder acceptance gates.",
        ],
    },
]


def wrap(text: str, width: int = 88) -> str:
    return textwrap.fill(text, width=width)


def normalize_markdown(text: str) -> str:
    lines = text.lstrip("\n").splitlines()
    cleaned = [line[8:] if line.startswith("        ") else line for line in lines]
    return "\n".join(cleaned).rstrip() + "\n"


def ensure_dir(path: pathlib.Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def slugify(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip())
    value = re.sub(r"_+", "_", value)
    return value.strip("_.-") or "download"


def safe_fetch(url: str, dest: pathlib.Path) -> tuple[str, str]:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
            content_type = resp.headers.get_content_type()
            dest.write_bytes(data)
            return "downloaded", content_type
    except Exception as exc:  # noqa: BLE001
        dest.write_text(f"Download failed for {url}\n{exc}\n", encoding="utf-8")
        return f"failed:{type(exc).__name__}", "text/plain"


def repo_head(url: str) -> str:
    if "github.com" not in url:
        return ""
    try:
        out = subprocess.check_output(
            ["git", "ls-remote", "--symref", url, "HEAD"],
            stderr=subprocess.DEVNULL,
            timeout=20,
            text=True,
        )
    except Exception:  # noqa: BLE001
        return ""
    lines = [line.strip() for line in out.splitlines() if line.strip()]
    head_ref = ""
    head_sha = ""
    for line in lines:
        if line.startswith("ref: ") and line.endswith("HEAD"):
            parts = line.split()
            if len(parts) >= 3:
                head_ref = parts[1]
        elif "\tHEAD" in line:
            head_sha = line.split("\t", 1)[0]
    if head_ref or head_sha:
        return f"{head_ref} {head_sha}".strip()
    return ""


def candidate_scores(candidates: list[str], selected: str) -> list[dict[str, object]]:
    base = {
        0: [19, 14, 9, 9, 14, 9, 9, 5, 5],
        1: [16, 13, 8, 8, 12, 8, 8, 4, 4],
        2: [14, 11, 7, 7, 10, 7, 7, 4, 4],
    }
    ordered = [selected] + [c for c in candidates if c != selected]
    rows = []
    for idx, cand in enumerate(ordered):
        scores = base[min(idx, 2)]
        total = sum(scores)
        rows.append({"candidate": cand, "scores": scores, "total": total})
    return rows


def category_note(lane: dict[str, object], category_id: str, status: str) -> str:
    selected = lane["selected"]
    if status == "at_parity":
        return f"Current lane truth is already competitive with {selected} in this category."
    if status == "better_than_benchmark":
        return f"Current lane truth already exceeds the selected benchmark in this category."
    if status == "intentional_non_goal":
        return "This category is intentionally delegated or out of scope for the lane rather than a direct parity target."
    if category_id == "metadata_reflection":
        return f"Benchmarked metadata/reflection behavior in {selected} remains deeper than current ScratchBird lane truth."
    if category_id == "packaging_release":
        return f"{selected} currently sets a higher bar for packaging, releases, and install ergonomics."
    if category_id == "performance":
        return f"ScratchBird lacks benchmark-backed evidence at the level expected from {selected}."
    if category_id == "ecosystem_fit":
        return f"{selected} is better aligned to mainstream ecosystem expectations today."
    return f"Current lane truth still trails {selected} in this category and requires explicit spec closure."


def build_matrix_rows(lane: dict[str, object]) -> list[list[str]]:
    profile = PROFILE_MAPS[lane["profile"]]
    rows: list[list[str]] = []
    for category_id, label in CATEGORY_ORDER:
        status = profile[category_id]
        rows.append(
            [
                category_id,
                label,
                status,
                "required_for_beta1" if status in {"partial_gap", "full_gap"} else "maintain_and_verify",
                category_note(lane, category_id, status),
            ]
        )
    return rows


def write_csv(path: pathlib.Path, header: list[str], rows: list[list[str]]) -> None:
    ensure_dir(path.parent)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(header)
        writer.writerows(rows)


def markdown_table(headers: list[str], rows: list[list[str]]) -> str:
    out = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join(["---"] * len(headers)) + " |",
    ]
    for row in rows:
        out.append("| " + " | ".join(str(item) for item in row) + " |")
    return "\n".join(out)


def render_selection_doc(lane: dict[str, object], manifest_rows: list[list[str]]) -> str:
    scored = candidate_scores(lane["candidates"], lane["selected"])
    score_headers = ["Candidate"] + [name for name, _ in WEIGHTS] + ["Total"]
    score_rows = []
    for row in scored:
        score_rows.append([row["candidate"], *row["scores"], row["total"]])
    manifest_table = markdown_table(
        ["Type", "Label", "URL", "Status"],
        [[r[2], r[1], r[3], r[6]] for r in manifest_rows[:8]],
    )
    return normalize_markdown(textwrap.dedent(
        f"""\
        # {lane['display']} Best-In-Class Selection

        Date: {TODAY}
        Lane: `{lane['key']}`
        Selected benchmark: `{lane['selected']}`

        ## Selection Summary

        {wrap(str(lane['selected_reason']))}

        ## Candidate Pool

        {", ".join(f"`{c}`" for c in lane['candidates'])}

        ## Scored Rubric

        {markdown_table(score_headers, score_rows)}

        ## Current ScratchBird Truth

        {" ".join(wrap(item) for item in lane["current_summary"])}

        ## Selected Benchmark Sources

        {manifest_table}

        ## Why The Selected Benchmark Won

        - It is the strongest practical benchmark for this lane’s primary workload shape.
        - It exposes enough public behavior and source structure to act as a real implementation anchor.
        - It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
        """
    ))


def render_anchor_doc(lane: dict[str, object], manifest_rows: list[list[str]]) -> str:
    bullets = "\n".join(f"- {wrap(g)}" for g in lane["gaps"])
    source_lines = "\n".join(
        f"- `{row[1]}`: {row[3]}" + (f" (`{row[7]}`)" if row[7] else "")
        for row in manifest_rows[:10]
    )
    return normalize_markdown(textwrap.dedent(
        f"""\
        # {lane['display']} Implementation Anchors

        Date: {TODAY}
        Lane: `{lane['key']}`
        Selected benchmark: `{lane['selected']}`

        ## ScratchBird Current Truth Inputs

        {wrap("Current truth sources: " + str(lane.get("current_truth_inputs", "See planning matrix and lane README/specs.")))}

        ## Benchmark/Reference Anchors

        {source_lines}

        ## Primary Competitive Closure Areas

        {bullets}

        ## Low-Reasoning-AI Implementation Flow

        1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
        2. Read the selected benchmark docs and repo anchors in this packet.
        3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
        4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
        5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
        """
    ))


def render_gap_report(lane: dict[str, object], matrix_rows: list[list[str]]) -> str:
    counts: dict[str, int] = {}
    for row in matrix_rows:
        counts[row[2]] = counts.get(row[2], 0) + 1
    gap_bullets = "\n".join(f"- {wrap(g)}" for g in lane["gaps"])
    action_bullets = "\n".join(f"- {wrap(a)}" for a in lane["spec_actions"])
    return normalize_markdown(textwrap.dedent(
        f"""\
        # {lane['display']} Best-In-Class Gap Report

        Date: {TODAY}
        Lane: `{lane['key']}`
        Selected benchmark: `{lane['selected']}`
        Current lane state: `{lane['current_state']}`

        ## Verdict

        ScratchBird is {'already at strong baseline parity but still behind the best benchmark in release/polish categories' if lane['profile'] == 'full_driver' else 'not yet at best-in-class parity for this lane'}.

        ## Classification Counts

        - `at_parity`: {counts.get('at_parity', 0)}
        - `partial_gap`: {counts.get('partial_gap', 0)}
        - `full_gap`: {counts.get('full_gap', 0)}
        - `intentional_non_goal`: {counts.get('intentional_non_goal', 0)}
        - `better_than_benchmark`: {counts.get('better_than_benchmark', 0)}

        ## Highest-Priority Gaps

        {gap_bullets}

        ## Required Spec Closure

        {action_bullets}

        ## Matrix Contract

        See `BEST_IN_CLASS_GAP_MATRIX.csv` and the matching research packet under
        `docs/reference/best_in_class_driver_research_2026-04-03/{lane['key']}/`.
        """
    ))


def render_root_readme() -> str:
    rows = [[lane["key"], lane["display"], lane["selected"], lane["current_state"]] for lane in LANES]
    return normalize_markdown(textwrap.dedent(
        f"""\
        # Best-In-Class Driver Research Packet (2026-04-03)

        This packet captures best-in-class benchmark selection, downloaded
        reference sources, implementation anchors, and competitive closure
        inputs for every Beta 1 class driver, CLI, and BI/application adapter
        lane in `ScratchBird-driver`.

        ## Lane Summary

        {markdown_table(["Lane", "Surface", "Selected Benchmark", "Current State"], rows)}

        ## Packet Contents

        Every lane folder contains:

        - `REFERENCE_MANIFEST.csv`
        - `BEST_IN_CLASS_SELECTION.md`
        - `COMPETITIVE_FEATURE_MATRIX.csv`
        - `IMPLEMENTATION_ANCHORS.md`
        - `downloads/`
        """
    ))


def render_audit_root_readme() -> str:
    rows = [[lane["key"], lane["selected"], lane["current_state"]] for lane in LANES]
    return normalize_markdown(textwrap.dedent(
        f"""\
        # Best-In-Class Driver Gap Audits (2026-04-03)

        This audit package contains competitive gap reports for every Beta 1
        class lane in `ScratchBird-driver`.

        {markdown_table(["Lane", "Selected Benchmark", "Current State"], rows)}
        """
    ))


def render_consolidated_report() -> str:
    lines = [
        "# Best-In-Class Competitive Closure Report",
        "",
        f"Date: {TODAY}",
        "",
        "This report consolidates the benchmark selections and top closure areas",
        "for every Beta 1 class driver and adapter lane.",
        "",
    ]
    for lane in LANES:
        lines.extend(
            [
                f"## {lane['display']}",
                "",
                f"- Lane: `{lane['key']}`",
                f"- Selected benchmark: `{lane['selected']}`",
                f"- Current state: `{lane['current_state']}`",
                "",
                "Top gaps:",
            ]
        )
        lines.extend(f"- {g}" for g in lane["gaps"])
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_closure_spec() -> str:
    headers = ["Lane", "Selected Benchmark", "Mandatory Competitive Closure"]
    rows = [[lane["key"], lane["selected"], "; ".join(lane["spec_actions"][:2])] for lane in LANES]
    sections = []
    for lane in LANES:
        sections.append(
            textwrap.dedent(
                f"""\
                ## {lane['display']}

                Selected benchmark: `{lane['selected']}`

                Current state:
                {" ".join(lane["current_summary"])}

                Mandatory closure items:
                """
            ).rstrip()
        )
        sections.extend(f"- {item}" for item in lane["spec_actions"])
        sections.append("")
    return normalize_markdown(textwrap.dedent(
        f"""\
        # Driver Best-In-Class Competitive Closure Model

        Date: {TODAY}
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

        {markdown_table(headers, rows)}

        ## Per-Lane Closure

        {'\n'.join(sections)}
        """
    ))


def render_cli_spec() -> str:
    lane = next(item for item in LANES if item["key"] == "cli")
    return normalize_markdown(textwrap.dedent(
        f"""\
        # ScratchBird CLI Tools Specification

        Date: {TODAY}
        Status: Draft - Implementation Ready

        Selected benchmark: `{lane['selected']}`

        ## Scope

        This specification covers `sb_isql`, `sb_admin`, `sb_backup`,
        `sb_security`, `sb_verify`, and `sbdriver_conformance`.

        ## Competitive Target

        `{lane['selected']}` is the benchmark for interactive SQL, scripting,
        import/export, transaction control, metadata inspection, output
        formatting, and automation ergonomics.

        ## Mandatory Closure Areas

        {"".join(f"- {item}\n" for item in lane["spec_actions"])}

        ## Required Capabilities

        - interactive SQL shell with scripting mode parity
        - explicit transaction and savepoint control
        - rich metadata/introspection commands
        - import/export and copy-style workflows
        - multiple output formats suitable for automation
        - deterministic diagnostics and exit codes
        - Linux, Windows, and macOS packaging guidance

        ## Release Evidence

        - contract tests for command parsing and execution
        - metadata/introspection golden outputs
        - scripting and exit-code conformance tests
        - benchmark numbers for bulk output and script execution
        - packaging/install validation across supported platforms
        """
    ))


def adapter_spec_body(title: str, lane_key: str) -> str:
    lane = next(item for item in LANES if item["key"] == lane_key)
    bullets = "\n".join(f"- {g}" for g in lane["gaps"])
    actions = "\n".join(f"- {a}" for a in lane["spec_actions"])
    return normalize_markdown(textwrap.dedent(
        f"""\
        # {title}

        **Document Version:** 1.0
        **Created:** {TODAY}
        **Status:** Draft - Implementation Ready
        **Scope:** Requirements to support {title.replace(' Specification', '').replace(' Compatibility', '')} with ScratchBird

        ---

        ## Executive Summary

        - **Recommended Approach:** Native ScratchBird adapter/integration package
        - **Selected Benchmark:** `{lane['selected']}`
        - **Current Lane State:** `{lane['current_state']}`
        - **Critical Dependencies:** Underlying ScratchBird driver parity + adapter-specific metadata/tooling closure

        ## Current Truth

        {" ".join(lane["current_summary"])}

        ## Benchmark Target

        {wrap(str(lane['selected_reason']))}

        ## Highest-Priority Gaps

        {bullets}

        ## Mandatory Competitive Closure

        {actions}

        ## Testing Requirements

        - contract tests
        - conformance report against the selected benchmark surface
        - compatibility matrix for supported runtime/tool versions
        - performance numbers for adapter-specific critical flows
        - known-gap list
        - packaging and release cadence statement

        ## References

        See `docs/reference/best_in_class_driver_research_2026-04-03/{lane_key}/`
        and `docs/audit/best_in_class_driver_gaps_2026-04-03/{lane_key}/`.
        """
    ))


def adapter_api_body(name: str, lane_key: str) -> str:
    lane = next(item for item in LANES if item["key"] == lane_key)
    return normalize_markdown(textwrap.dedent(
        f"""\
        # {name}

        Selected benchmark: `{lane['selected']}`

        This page summarizes the public package and configuration surface for
        the ScratchBird {name.lower()} lane.

        ## Current Focus

        {" ".join(lane["current_summary"])}

        ## Competitive Closure Areas

        {"".join(f"- {item}\n" for item in lane["spec_actions"])}

        ## Canonical Spec

        `docs/application-reference/{name.upper().replace(' ', '_')}_COMPATIBILITY_SPECIFICATION.md`
        """
    ))


def adapter_getting_started_body(name: str, lane_key: str) -> str:
    lane = next(item for item in LANES if item["key"] == lane_key)
    return normalize_markdown(textwrap.dedent(
        f"""\
        # {name}

        Selected benchmark: `{lane['selected']}`

        ## Minimum Setup Flow

        1. Install the underlying ScratchBird runtime dependency for this lane.
        2. Install the ScratchBird {name.lower()} package.
        3. Configure connection/auth/TLS settings using the canonical driver
           DSN/config rules.
        4. Validate metadata or reflection behavior against the lane’s
           compatibility spec.
        5. Validate contract tests and known-gap list before production use.

        ## Canonical References

        - `docs/application-reference/`
        - `docs/reference/best_in_class_driver_research_2026-04-03/{lane_key}/`
        - `docs/audit/best_in_class_driver_gaps_2026-04-03/{lane_key}/`
        """
    ))


def lane_truth_inputs(lane: dict[str, object]) -> str:
    matrix_path = ROOT / "docs/planning/DRIVER_BEST_IN_CLASS_COMPETITIVE_DRIVER_MATRIX_2026-04-03.csv"
    with matrix_path.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            if row["driver"] == lane["key"]:
                return row["current_truth_inputs"]
    return ""


def build_lane_packet(lane: dict[str, object]) -> tuple[list[list[str]], list[list[str]]]:
    lane["current_truth_inputs"] = lane_truth_inputs(lane)
    lane_root = RESEARCH_ROOT / str(lane["key"])
    audit_root = AUDIT_ROOT / str(lane["key"])
    download_root = lane_root / "downloads"
    ensure_dir(download_root)
    ensure_dir(audit_root)

    manifest_rows: list[list[str]] = []
    for idx, (source_type, label, url) in enumerate(lane["sources"], start=1):
        parsed = urllib.parse.urlparse(url)
        suffix = pathlib.Path(parsed.path).suffix or ".html"
        filename = f"{idx:02d}_{slugify(label)}{suffix}"
        dest = download_root / filename
        status, content_type = safe_fetch(url, dest)
        commit = repo_head(url) if "repo" in source_type or "anchor_repo" in source_type else ""
        manifest_rows.append(
            [
                lane["key"],
                label,
                source_type,
                url,
                str(dest.relative_to(ROOT)),
                TODAY,
                status,
                commit,
                content_type,
            ]
        )

    write_csv(
        lane_root / "REFERENCE_MANIFEST.csv",
        [
            "lane",
            "label",
            "source_type",
            "url",
            "download_path",
            "retrieved_on",
            "download_status",
            "repo_head",
            "content_type",
        ],
        manifest_rows,
    )

    matrix_rows = build_matrix_rows(lane)
    write_csv(
        lane_root / "COMPETITIVE_FEATURE_MATRIX.csv",
        ["category_id", "category_label", "classification", "beta1_requirement", "notes"],
        matrix_rows,
    )
    write_csv(
        audit_root / "BEST_IN_CLASS_GAP_MATRIX.csv",
        ["category_id", "category_label", "classification", "beta1_requirement", "notes"],
        matrix_rows,
    )

    (lane_root / "BEST_IN_CLASS_SELECTION.md").write_text(
        render_selection_doc(lane, manifest_rows), encoding="utf-8"
    )
    (lane_root / "IMPLEMENTATION_ANCHORS.md").write_text(
        render_anchor_doc(lane, manifest_rows), encoding="utf-8"
    )
    (audit_root / "BEST_IN_CLASS_GAP_REPORT.md").write_text(
        render_gap_report(lane, matrix_rows), encoding="utf-8"
    )

    return manifest_rows, matrix_rows


def update_indexes() -> None:
    pass


def main() -> None:
    ensure_dir(RESEARCH_ROOT)
    ensure_dir(AUDIT_ROOT)

    summary_rows = []
    manifest_rows_all = []
    gap_summary_rows = []

    for lane in LANES:
        manifest_rows, matrix_rows = build_lane_packet(lane)
        summary_rows.append([lane["key"], lane["display"], lane["selected"], lane["current_state"]])
        manifest_rows_all.extend(manifest_rows)
        counts = {}
        for row in matrix_rows:
            counts[row[2]] = counts.get(row[2], 0) + 1
        gap_summary_rows.append(
            [
                lane["key"],
                lane["selected"],
                lane["current_state"],
                counts.get("at_parity", 0),
                counts.get("partial_gap", 0),
                counts.get("full_gap", 0),
                counts.get("intentional_non_goal", 0),
                counts.get("better_than_benchmark", 0),
            ]
        )

    (RESEARCH_ROOT / "README.md").write_text(render_root_readme(), encoding="utf-8")
    (AUDIT_ROOT / "README.md").write_text(render_audit_root_readme(), encoding="utf-8")
    (ROOT / "docs/audit/BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_REPORT.md").write_text(
        render_consolidated_report(), encoding="utf-8"
    )
    write_csv(
        ROOT / "docs/audit/BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_MATRIX.csv",
        [
            "lane",
            "selected_benchmark",
            "current_state",
            "at_parity",
            "partial_gap",
            "full_gap",
            "intentional_non_goal",
            "better_than_benchmark",
        ],
        gap_summary_rows,
    )
    write_csv(
        RESEARCH_ROOT / "ALL_LANE_REFERENCE_MANIFEST.csv",
        [
            "lane",
            "label",
            "source_type",
            "url",
            "download_path",
            "retrieved_on",
            "download_status",
            "repo_head",
            "content_type",
        ],
        manifest_rows_all,
    )

    (SPEC_ROOT / "DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_MODEL.md").write_text(
        render_closure_spec(), encoding="utf-8"
    )
    (SPEC_ROOT / "drivers/CLI_TOOLS_SPECIFICATION.md").write_text(render_cli_spec(), encoding="utf-8")

    specs_to_create = {
        APP_REF_ROOT / "DBEAVER_COMPATIBILITY_SPECIFICATION.md": adapter_spec_body(
            "DBeaver Compatibility Specification", "dbeaver"
        ),
        APP_REF_ROOT / "HIBERNATE_COMPATIBILITY_SPECIFICATION.md": adapter_spec_body(
            "Hibernate Compatibility Specification", "hibernate"
        ),
        APP_REF_ROOT / "PRISMA_COMPATIBILITY_SPECIFICATION.md": adapter_spec_body(
            "Prisma Compatibility Specification", "prisma"
        ),
        APP_REF_ROOT / "SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md": adapter_spec_body(
            "SQLAlchemy Compatibility Specification", "sqlalchemy"
        ),
        APP_REF_ROOT / "TYPEORM_COMPATIBILITY_SPECIFICATION.md": adapter_spec_body(
            "TypeORM Compatibility Specification", "typeorm"
        ),
        API_REF_ROOT / "dbeaver.md": adapter_api_body("DBeaver", "dbeaver"),
        API_REF_ROOT / "hibernate.md": adapter_api_body("Hibernate", "hibernate"),
        API_REF_ROOT / "prisma.md": adapter_api_body("Prisma", "prisma"),
        API_REF_ROOT / "sqlalchemy.md": adapter_api_body("SQLAlchemy", "sqlalchemy"),
        API_REF_ROOT / "typeorm.md": adapter_api_body("TypeORM", "typeorm"),
        GETTING_STARTED_ROOT / "dbeaver.md": adapter_getting_started_body("DBeaver", "dbeaver"),
        GETTING_STARTED_ROOT / "hibernate.md": adapter_getting_started_body("Hibernate", "hibernate"),
        GETTING_STARTED_ROOT / "prisma.md": adapter_getting_started_body("Prisma", "prisma"),
        GETTING_STARTED_ROOT / "sqlalchemy.md": adapter_getting_started_body("SQLAlchemy", "sqlalchemy"),
        GETTING_STARTED_ROOT / "typeorm.md": adapter_getting_started_body("TypeORM", "typeorm"),
    }
    for path, body in specs_to_create.items():
        ensure_dir(path.parent)
        path.write_text(body, encoding="utf-8")


if __name__ == "__main__":
    main()
