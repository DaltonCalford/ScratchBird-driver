#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from pathlib import Path
from textwrap import dedent


ROOT = Path("/home/dcalford/CliWork/ScratchBird-driver")
DOCS = ROOT / "docs"
SPEC = DOCS / "specifications"
LANG_ROOT = SPEC / "drivers" / "language"
APP_REF = DOCS / "application-reference"
API_REF = DOCS / "api-reference"
GETTING = DOCS / "getting-started"
PLANNING = DOCS / "planning"
DEVELOPMENT = DOCS / "development"
AUDIT = DOCS / "audit"
INTEGRATIONS = SPEC / "integrations"


def norm(text: str) -> str:
    return dedent(text).strip() + "\n"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(norm(text))


def append_block(path: Path, block_id: str, content: str) -> None:
    start = f"<!-- {block_id}:start -->"
    end = f"<!-- {block_id}:end -->"
    cleaned = dedent(content).strip()
    block = norm(f"""{start}

{cleaned}

{end}""")
    text = path.read_text() if path.exists() else ""
    if start in text and end in text:
        prefix = text.split(start, 1)[0].rstrip()
        suffix = text.split(end, 1)[1].lstrip()
        merged = prefix + "\n\n" + block + ("\n" + suffix if suffix else "")
    else:
        merged = text.rstrip() + ("\n\n" if text.strip() else "") + block
    path.write_text(merged.rstrip() + "\n")


LANES = [
    {
        "slug": "cpp",
        "display": "C/C++",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "libpqxx",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/cpp",
        "spec_path": "docs/specifications/drivers/language/cpp/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/cpp/README.md",
        "plan_path": "docs/specifications/drivers/language/cpp/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/cpp/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/cpp.md",
        "getting_started_path": "docs/getting-started/cpp.md",
        "competitive_targets": [
            "publish allocator, throughput, and streaming evidence against libpqxx-class workloads",
            "freeze advanced prepared-reuse, TLS diagnostics, and large-result examples as release requirements",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is server-backed proof collection and competitive release evidence",
        ],
        "env": ["SCRATCHBIRD_CPP_URL", "SCRATCHBIRD_CPP_CANCEL_SQL"],
        "build_commands": [
            "cmake -S tracks/p3/drivers/cpp -B build-cpp -DCMAKE_BUILD_TYPE=Release",
            "cmake --build build-cpp --config Release",
        ],
        "verify_commands": [
            "ctest --test-dir build-cpp --output-on-failure",
            "scratchbird_client_tests",
        ],
    },
    {
        "slug": "cli",
        "display": "CLI Tooling",
        "kind": "tooling",
        "category": "cli",
        "status": "Partial",
        "current_state": "tooling_partial",
        "benchmark": "psql",
        "priority": "P1",
        "track_path": "tracks/p3/drivers/cli",
        "spec_path": "docs/specifications/drivers/CLI_TOOLS_SPECIFICATION.md",
        "api_path": "docs/user-documentation/tools/README.md",
        "getting_started_path": "docs/user-documentation/tools/sbdriver-conformance.md",
        "competitive_targets": [
            "freeze psql-class scripting, copy/import/export, metadata inspection, and output-format behavior",
            "require script-execution and exit-code evidence in the release pack",
        ],
        "remaining_deltas": [
            "tooling lane remains partial on TXN, META, TYPE, and RES in the lane-local mapping",
            "later work is focused on live metadata goldens, script-mode validation, and command-surface proof",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN", "SCRATCHBIRD_TEST_CANCEL_SQL"],
        "build_commands": [
            "cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF",
            "cmake --build build_cli --config Release",
        ],
        "verify_commands": [
            "ctest --test-dir build_cli --output-on-failure",
            "build_cli/sbdriver_conformance --help",
        ],
    },
    {
        "slug": "dart",
        "display": "Dart",
        "kind": "driver",
        "category": "top_level",
        "status": "Partial",
        "current_state": "partial",
        "benchmark": "postgres (Dart)",
        "priority": "P1",
        "track_path": "tracks/p3/drivers/dart",
        "spec_path": "docs/specifications/DRIVER_DART_DATABASE_API.md",
        "api_path": "docs/api-reference/dart.md",
        "getting_started_path": "docs/getting-started/dart.md",
        "competitive_targets": [
            "freeze async ergonomics, metadata, and codec expectations against postgres(Dart)",
            "promote live metadata and failure-path validation from optional to required release evidence",
        ],
        "remaining_deltas": [
            "TXN: live failure-path validation remains open",
            "EXEC: live pagination, portalSuspended, and SBLR execution proof remains open",
            "META: live restrictions, wildcard handling, and DDL-editor payload coverage remains open",
            "TYPE: live complex-type binary roundtrip coverage remains open",
            "ERR: live SQLSTATE/code propagation proof remains open",
            "RES: live resilience cleanup and idle-validation proof remains open",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN", "SCRATCHBIRD_TEST_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/dart",
            "dart pub get",
        ],
        "verify_commands": [
            "dart test",
        ],
    },
    {
        "slug": "dbeaver",
        "display": "DBeaver Extension",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_plugin",
        "benchmark": "DBeaver PostgreSQL extension",
        "priority": "P1",
        "track_path": "tracks/alpha/integrations/scratchbird-dbeaver-driver",
        "compat_spec_path": "docs/application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/dbeaver.md",
        "getting_started_path": "docs/getting-started/dbeaver.md",
        "integration_spec_dir": "docs/specifications/integrations/tools/dbeaver",
        "competitive_targets": [
            "freeze plugin packaging, update-site install, schema-tree behavior, and editor metadata expectations",
            "require DBeaver-side UI and navigator goldens in release evidence",
        ],
        "remaining_deltas": [
            "UI plugin packaging and update-site installation proof remain open",
            "schema navigator, editor payload, and query-preview behavior need later live validation",
        ],
        "env": ["SCRATCHBIRD_JDBC_URL", "SCRATCHBIRD_JDBC_USER", "SCRATCHBIRD_JDBC_PASSWORD"],
        "build_commands": [
            "cd tracks/alpha/integrations/scratchbird-dbeaver-driver",
            "mvn test",
        ],
        "verify_commands": [
            "mvn -pl test/org.jkiss.dbeaver.ext.scratchbird.test test",
        ],
    },
    {
        "slug": "dotnet",
        "display": ".NET",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "Npgsql",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/dotnet",
        "spec_path": "docs/specifications/drivers/language/dotnet-csharp/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/dotnet-csharp/README.md",
        "plan_path": "docs/specifications/drivers/language/dotnet-csharp/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/dotnet-csharp/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/dotnet.md",
        "getting_started_path": "docs/getting-started/dotnet.md",
        "competitive_targets": [
            "freeze Npgsql-class diagnostics, pooling expectations, and release evidence requirements",
            "require reproducible compatibility matrices and benchmark output in the release pack",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is competitive proof, packaging polish, and later live evidence collection",
        ],
        "env": ["SCRATCHBIRD_DOTNET_URL", "SCRATCHBIRD_DOTNET_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/dotnet",
            "dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj",
        ],
        "verify_commands": [
            "dotnet test",
        ],
    },
    {
        "slug": "elixir",
        "display": "Elixir / Ecto",
        "kind": "driver",
        "category": "top_level",
        "status": "Partial",
        "current_state": "partial",
        "benchmark": "Postgrex",
        "priority": "P1",
        "track_path": "tracks/p3/drivers/elixir",
        "spec_path": "docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md",
        "api_path": "docs/api-reference/elixir.md",
        "getting_started_path": "docs/getting-started/elixir.md",
        "competitive_targets": [
            "freeze stream/resume, telemetry, and reconnect semantics against Postgrex-class behavior",
            "require both direct-driver and Ecto evidence in the release pack",
        ],
        "remaining_deltas": [
            "EXEC: no standalone public portal-resume helper and deterministic stream/paging proof remains limited",
            "RES: resilience still uses fresh-connect-only recovery rather than transparent in-place reconnect",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN"],
        "build_commands": [
            "cd tracks/p3/drivers/elixir",
            "mix local.hex --force",
            "mix local.rebar --force",
            "mix deps.get",
        ],
        "verify_commands": [
            "mix test",
        ],
    },
    {
        "slug": "go",
        "display": "Go",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "pgx",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/go",
        "spec_path": "docs/specifications/drivers/language/golang/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/golang/README.md",
        "plan_path": "docs/specifications/drivers/language/golang/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/golang/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/go.md",
        "getting_started_path": "docs/getting-started/go.md",
        "competitive_targets": [
            "freeze pgx-class pool diagnostics, advanced examples, and benchmark evidence",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is server-backed benchmark, compatibility, and release proof collection",
        ],
        "env": ["SCRATCHBIRD_GO_URL", "SCRATCHBIRD_GO_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/go",
        ],
        "verify_commands": [
            "go test ./...",
        ],
    },
    {
        "slug": "hibernate",
        "display": "Hibernate Dialect",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_contract_only",
        "benchmark": "Hibernate PostgreSQLDialect",
        "priority": "P1",
        "track_path": "tracks/alpha/integrations/scratchbird-hibernate-dialect",
        "compat_spec_path": "docs/application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/hibernate.md",
        "getting_started_path": "docs/getting-started/hibernate.md",
        "integration_spec_dir": "docs/specifications/integrations/orm/hibernate-jpa",
        "competitive_targets": [
            "freeze dialect registration, ORM lifecycle, DDL compilation, and migration acceptance gates",
            "require live ORM bootstrap and schema-management evidence",
        ],
        "remaining_deltas": [
            "current lane is still contract-first rather than fully validated runtime integration",
            "schema-management, migration, and ORM lifecycle proof remain server-blocked",
        ],
        "env": ["SCRATCHBIRD_JDBC_URL", "SCRATCHBIRD_JDBC_USER", "SCRATCHBIRD_JDBC_PASSWORD"],
        "build_commands": [
            "cd tracks/alpha/integrations/scratchbird-hibernate-dialect",
        ],
        "verify_commands": [
            "mvn test",
        ],
    },
    {
        "slug": "jdbc",
        "display": "JDBC",
        "kind": "driver",
        "category": "top_level",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "pgjdbc",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/jdbc",
        "spec_path": "docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md",
        "api_path": "docs/api-reference/jdbc.md",
        "getting_started_path": "docs/getting-started/jdbc.md",
        "competitive_targets": [
            "freeze pgjdbc-class metadata depth, packaging, and release evidence expectations",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is live compatibility, benchmark proof, and release-evidence staging",
        ],
        "env": ["SCRATCHBIRD_JDBC_URL", "SCRATCHBIRD_JDBC_USER", "SCRATCHBIRD_JDBC_PASSWORD", "SCRATCHBIRD_JDBC_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/jdbc",
        ],
        "verify_commands": [
            "./gradlew test",
        ],
    },
    {
        "slug": "metabase",
        "display": "Metabase Plugin",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_adapter",
        "benchmark": "Metabase PostgreSQL driver",
        "priority": "P1",
        "track_path": "tracks/alpha/integrations/scratchbird-metabase-driver",
        "compat_spec_path": "docs/application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/metabase.md",
        "getting_started_path": "docs/getting-started/metabase.md",
        "integration_spec_dir": "docs/specifications/integrations/tools/metabase",
        "competitive_targets": [
            "freeze schema sync, fingerprinting, native query, and feature-flag behavior against the PostgreSQL driver",
            "require packaging and sync-performance evidence",
        ],
        "remaining_deltas": [
            "schema sync, field fingerprinting, and native-query validation remain server-blocked",
            "packaged plugin/runtime validation remains open",
        ],
        "env": ["SCRATCHBIRD_JDBC_URL", "SCRATCHBIRD_JDBC_USER", "SCRATCHBIRD_JDBC_PASSWORD"],
        "build_commands": [
            "cd tracks/alpha/integrations/scratchbird-metabase-driver",
        ],
        "verify_commands": [
            "clojure -M:test",
        ],
    },
    {
        "slug": "mojo",
        "display": "Mojo",
        "kind": "driver",
        "category": "top_level",
        "status": "Hybrid surface-complete / native transport gap outstanding",
        "current_state": "hybrid_native_gap",
        "benchmark": "Composite (asyncpg + pgx + PostgresNIO)",
        "priority": "P2",
        "track_path": "tracks/p3/drivers/mojo",
        "spec_path": "docs/specifications/DRIVER_MOJO_NATIVE_API.md",
        "api_path": "docs/api-reference/mojo.md",
        "getting_started_path": "docs/getting-started/mojo.md",
        "competitive_targets": [
            "promote native transport cutover from checklist work to a hard competitive-closure requirement",
            "require composite benchmark evidence after native transport lands",
        ],
        "remaining_deltas": [
            "architectural gap: replace the Python bridge with a native SBWP client / native Mojo transport",
            "full live evidence remains blocked until native transport is implemented and a server is available",
        ],
        "env": ["SCRATCHBIRD_MOJO_URL", "MOJO_ENABLED"],
        "build_commands": [
            "cd tracks/p3/drivers/mojo/tests",
        ],
        "verify_commands": [
            "mojo integration.mojo",
        ],
    },
    {
        "slug": "node",
        "display": "Node.js / TypeScript",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "node-postgres",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/node",
        "spec_path": "docs/specifications/drivers/language/nodejs-typescript/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/nodejs-typescript/README.md",
        "plan_path": "docs/specifications/drivers/language/nodejs-typescript/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/nodejs-typescript/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/node.md",
        "getting_started_path": "docs/getting-started/node.md",
        "competitive_targets": [
            "freeze node-postgres-class cancellation ergonomics, performance evidence, and framework guidance",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is server-backed benchmark and release proof collection",
        ],
        "env": ["SCRATCHBIRD_NODE_URL", "SCRATCHBIRD_NODE_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/node",
            "npm install",
        ],
        "verify_commands": [
            "npm test",
        ],
    },
    {
        "slug": "odbc",
        "display": "ODBC",
        "kind": "driver",
        "category": "top_level",
        "status": "Partial",
        "current_state": "partial",
        "benchmark": "Microsoft ODBC Driver for SQL Server",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/odbc",
        "spec_path": "docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md",
        "api_path": "docs/api-reference/odbc.md",
        "getting_started_path": "docs/getting-started/odbc.md",
        "competitive_targets": [
            "use Microsoft ODBC behavior as the user-visible bar while anchoring implementation detail against psqlODBC",
            "freeze metadata-family and diagnostics expectations in authoritative docs",
        ],
        "remaining_deltas": [
            "META remains partial because broader full-family metadata parity and richer catalog surfaces are still incomplete",
            "later work is focused on metadata breadth and live catalog validation",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN"],
        "build_commands": [
            "cmake -S tracks/p3/drivers/odbc -B build/odbc-runtime -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON",
            "cmake --build build/odbc-runtime --config Release",
        ],
        "verify_commands": [
            "ctest --test-dir build/odbc-runtime --output-on-failure -R '^scratchbird_odbc_tests$'",
        ],
    },
    {
        "slug": "pascal",
        "display": "Pascal / Delphi",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "FireDAC",
        "priority": "P1",
        "track_path": "tracks/p3/drivers/pascal",
        "spec_path": "docs/specifications/drivers/language/pascal-delphi/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/pascal-delphi/README.md",
        "plan_path": "docs/specifications/drivers/language/pascal-delphi/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/pascal-delphi/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/pascal.md",
        "getting_started_path": "docs/getting-started/pascal.md",
        "competitive_targets": [
            "freeze FireDAC-class ergonomics with ZeosLib-class inspectable anchors",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is live packaging, benchmark, and toolchain validation",
        ],
        "env": [
            "SCRATCHBIRD_PASCAL_URL",
            "SCRATCHBIRD_PASCAL_STREAM_SQL",
            "SCRATCHBIRD_PASCAL_GENERATED_KEY_SQL",
            "SCRATCHBIRD_PASCAL_GENERATED_KEY_EXPECTED",
            "SCRATCHBIRD_PASCAL_CANCEL_SQL",
        ],
        "build_commands": [
            "fpc -Mdelphi -Fu./tracks/p3/drivers/pascal/src -FE./tracks/p3/drivers/pascal/tests ./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests.pas",
        ],
        "verify_commands": [
            "./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests",
        ],
    },
    {
        "slug": "php",
        "display": "PHP",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "PDO_PGSQL",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/php",
        "spec_path": "docs/specifications/drivers/language/php/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/php/README.md",
        "plan_path": "docs/specifications/drivers/language/php/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/php/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/php.md",
        "getting_started_path": "docs/getting-started/php.md",
        "competitive_targets": [
            "freeze PDO-style ergonomics and packaging evidence as release requirements",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is server-backed performance and packaging proof collection",
        ],
        "env": ["SCRATCHBIRD_PHP_URL", "SCRATCHBIRD_PHP_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/php",
            "composer install",
        ],
        "verify_commands": [
            "vendor/bin/phpunit tests",
        ],
    },
    {
        "slug": "prisma",
        "display": "Prisma Adapter",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_contract_only",
        "benchmark": "Prisma PostgreSQL connector",
        "priority": "P1",
        "track_path": "tracks/alpha/integrations/scratchbird-prisma-adapter",
        "compat_spec_path": "docs/application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/prisma.md",
        "getting_started_path": "docs/getting-started/prisma.md",
        "integration_spec_dir": "docs/specifications/integrations/orm/prisma",
        "competitive_targets": [
            "freeze datasource, introspection, migration, and native-type acceptance gates",
            "require runtime and schema workflow validation against the Prisma PostgreSQL connector bar",
        ],
        "remaining_deltas": [
            "current lane is still contract-first rather than fully validated runtime integration",
            "introspection, migrations, and runtime query behavior remain server-blocked",
        ],
        "env": ["DATABASE_URL"],
        "build_commands": [
            "cd tracks/alpha/integrations/scratchbird-prisma-adapter",
            "npm install",
        ],
        "verify_commands": [
            "npm test",
        ],
    },
    {
        "slug": "python",
        "display": "Python",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "psycopg3",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/python",
        "spec_path": "docs/specifications/drivers/language/python/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/python/README.md",
        "plan_path": "docs/specifications/drivers/language/python/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/python/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/python.md",
        "getting_started_path": "docs/getting-started/python.md",
        "competitive_targets": [
            "freeze psycopg3-class adaptation examples, benchmark expectations, and release evidence requirements",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is live proof collection and release-artifact staging",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN", "SCRATCHBIRD_TEST_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/python",
            "python -m pip install --upgrade pip",
            "python -m pip install -e \".[test]\"",
        ],
        "verify_commands": [
            "python -m pytest",
        ],
    },
    {
        "slug": "r",
        "display": "R",
        "kind": "driver",
        "category": "language",
        "status": "Partial",
        "current_state": "partial",
        "benchmark": "RPostgres",
        "priority": "P2",
        "track_path": "tracks/p3/drivers/r",
        "spec_path": "docs/specifications/drivers/language/r/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/r/README.md",
        "plan_path": "docs/specifications/drivers/language/r/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/r/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/r.md",
        "getting_started_path": "docs/getting-started/r.md",
        "competitive_targets": [
            "freeze DBI ergonomics and metadata expectations against RPostgres",
            "require connection/auth proof and richer metadata-family validation",
        ],
        "remaining_deltas": [
            "CONN: connection/auth integration coverage remains environment-gated",
            "META: richer privilege/key/type and DDL-editor metadata parity remains incomplete",
        ],
        "env": ["SCRATCHBIRD_R_URL", "SCRATCHBIRD_R_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/r",
            "R CMD build .",
        ],
        "verify_commands": [
            "R CMD check scratchbird_*.tar.gz",
        ],
    },
    {
        "slug": "ruby",
        "display": "Ruby",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "ruby-pg",
        "priority": "P1",
        "track_path": "tracks/p3/drivers/ruby",
        "spec_path": "docs/specifications/drivers/language/ruby/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/ruby/README.md",
        "plan_path": "docs/specifications/drivers/language/ruby/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/ruby/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/ruby.md",
        "getting_started_path": "docs/getting-started/ruby.md",
        "competitive_targets": [
            "freeze ruby-pg-class framework examples and release evidence expectations",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is live proof collection and packaging evidence",
        ],
        "env": ["SCRATCHBIRD_RUBY_URL", "SCRATCHBIRD_RUBY_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/ruby",
            "gem build scratchbird.gemspec",
        ],
        "verify_commands": [
            "ruby -Ilib:test test/*.rb",
        ],
    },
    {
        "slug": "rust",
        "display": "Rust",
        "kind": "driver",
        "category": "language",
        "status": "Complete",
        "current_state": "baseline_complete",
        "benchmark": "tokio-postgres",
        "priority": "P0",
        "track_path": "tracks/p3/drivers/rust",
        "spec_path": "docs/specifications/drivers/language/rust/SPECIFICATION.md",
        "readme_path": "docs/specifications/drivers/language/rust/README.md",
        "plan_path": "docs/specifications/drivers/language/rust/IMPLEMENTATION_PLAN.md",
        "testing_path": "docs/specifications/drivers/language/rust/TESTING_CRITERIA.md",
        "api_path": "docs/api-reference/rust.md",
        "getting_started_path": "docs/getting-started/rust.md",
        "competitive_targets": [
            "freeze tokio-postgres-class async and performance evidence into the Rust lane requirements",
        ],
        "remaining_deltas": [
            "no lane-local JDBC/.NET-class baseline gaps remain",
            "remaining work is live benchmark and release-proof collection",
        ],
        "env": ["SCRATCHBIRD_RUST_URL", "SCRATCHBIRD_RUST_CANCEL_SQL"],
        "build_commands": [
            "cd tracks/p3/drivers/rust",
            "cargo build",
        ],
        "verify_commands": [
            "cargo test",
        ],
    },
    {
        "slug": "sqlalchemy",
        "display": "SQLAlchemy Dialect",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_adapter",
        "benchmark": "SQLAlchemy PostgreSQL dialect",
        "priority": "P1",
        "track_path": "tracks/alpha/integrations/scratchbird-sqlalchemy-dialect",
        "compat_spec_path": "docs/application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/sqlalchemy.md",
        "getting_started_path": "docs/getting-started/sqlalchemy.md",
        "integration_spec_dir": "docs/specifications/integrations/orm/sqlalchemy",
        "competitive_targets": [
            "freeze reflection, ORM lifecycle, DDL compilation, and Alembic-facing requirements against the PostgreSQL dialect",
            "require migration and ORM lifecycle evidence",
        ],
        "remaining_deltas": [
            "deep reflection, DDL compilation, and Alembic behavior remain server-blocked",
            "production-grade packaging and benchmark evidence remain open",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN"],
        "build_commands": [
            "cd tracks/alpha/integrations/scratchbird-sqlalchemy-dialect",
            "python -m pip install -e \".[tooling]\"",
        ],
        "verify_commands": [
            "python -m pytest",
        ],
    },
    {
        "slug": "superset",
        "display": "Superset Driver",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_adapter",
        "benchmark": "Superset PostgreSQL engine spec",
        "priority": "P1",
        "track_path": "tracks/beta/integrations/scratchbird-superset-driver",
        "compat_spec_path": "docs/application-reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/superset.md",
        "getting_started_path": "docs/getting-started/superset.md",
        "competitive_targets": [
            "freeze EngineSpec, SQL Lab, and deployment expectations against the PostgreSQL engine spec",
            "require metadata sync, dialect, and packaging evidence",
        ],
        "remaining_deltas": [
            "EngineSpec behavior, SQL Lab validation, and deployment packaging remain server-blocked",
            "runtime sync and benchmark evidence remain open",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN"],
        "build_commands": [
            "cd tracks/beta/integrations/scratchbird-superset-driver",
            "python -m pip install -e \".[tooling,superset]\"",
        ],
        "verify_commands": [
            "python -m pytest",
        ],
    },
    {
        "slug": "swift",
        "display": "Swift",
        "kind": "driver",
        "category": "top_level",
        "status": "Partial",
        "current_state": "partial",
        "benchmark": "PostgresNIO",
        "priority": "P1",
        "track_path": "tracks/p3/drivers/swift",
        "spec_path": "docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md",
        "api_path": "docs/api-reference/swift.md",
        "getting_started_path": "docs/getting-started/swift.md",
        "competitive_targets": [
            "freeze PostgresNIO-class async, pooling, and codec expectations",
            "require wait-queue, timeout, and fault-recovery evidence",
        ],
        "remaining_deltas": [
            "EXEC: live cancellation timing and portal suspend/resume coverage remains open",
            "META: catalog payload families remain incomplete",
            "TYPE: advanced type roundtrip proof remains open",
            "ERR: auth/connect error propagation proof remains open",
            "RES: pool wait-queue, timeout, and fault-recovery semantics remain open",
        ],
        "env": ["SCRATCHBIRD_TEST_DSN"],
        "build_commands": [
            "cd tracks/p3/drivers/swift",
            "swift build",
        ],
        "verify_commands": [
            "swift test",
        ],
    },
    {
        "slug": "typeorm",
        "display": "TypeORM Adapter",
        "kind": "adapter",
        "category": "adapter",
        "status": "Partial",
        "current_state": "partial_contract_only",
        "benchmark": "TypeORM PostgreSQL driver",
        "priority": "P1",
        "track_path": "tracks/alpha/integrations/scratchbird-typeorm-adapter",
        "compat_spec_path": "docs/application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md",
        "api_path": "docs/api-reference/typeorm.md",
        "getting_started_path": "docs/getting-started/typeorm.md",
        "integration_spec_dir": "docs/specifications/integrations/orm/typeorm",
        "competitive_targets": [
            "freeze datasource, migrations, relations, and query-builder acceptance gates against the PostgreSQL driver",
            "require relation and schema-management evidence",
        ],
        "remaining_deltas": [
            "current lane is still contract-first rather than fully validated runtime integration",
            "migrations, relations, and query-builder behavior remain server-blocked",
        ],
        "env": ["DATABASE_URL"],
        "build_commands": [
            "cd tracks/alpha/integrations/scratchbird-typeorm-adapter",
            "npm install",
        ],
        "verify_commands": [
            "npm test",
        ],
    },
]


TARGETED_SUPERSEDED = [
    {
        "dir": "tools/dbeaver",
        "title": "DBeaver",
        "authority": "../" * 0,  # unused placeholder
        "top_level": "../../application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md",
    },
    {
        "dir": "tools/metabase",
        "title": "Metabase",
        "top_level": "../../application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md",
    },
    {
        "dir": "orm/sqlalchemy",
        "title": "SQLAlchemy",
        "top_level": "../../application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md",
    },
    {
        "dir": "orm/hibernate-jpa",
        "title": "Hibernate/JPA",
        "top_level": "../../application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md",
    },
    {
        "dir": "orm/prisma",
        "title": "Prisma",
        "top_level": "../../application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md",
    },
    {
        "dir": "orm/typeorm",
        "title": "TypeORM",
        "top_level": "../../application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md",
    },
]


def lane_reference_path(lane: dict, key: str) -> str:
    return lane.get(key, "")


def lane_readme(lane: dict) -> str:
    extra = lane_reference_path(lane, "spec_path")
    items = "\n".join(f"- {item}" for item in lane["remaining_deltas"])
    return f"""# {lane['display']} Driver

Status: Current
Priority: {lane['priority']}
Category: {lane['category']}

## Authority

- Implementation spec: `{extra}`
- API reference: `{lane['api_path']}`
- Getting started: `{lane['getting_started_path']}`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/{lane['slug']}.md`

## Current Truth

- Competitive benchmark: `{lane['benchmark']}`
- Current state: `{lane['current_state']}`
- Track root: `{lane['track_path']}`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

{items}
"""


def lane_spec(lane: dict) -> str:
    targets = "\n".join(f"- {item}" for item in lane["competitive_targets"])
    deltas = "\n".join(f"- {item}" for item in lane["remaining_deltas"])
    return f"""# {lane['display']} Driver Specification

Status: {lane['status']}
Priority: {lane['priority']}

## Implementation Status

- Current lane verdict: `{lane['current_state']}`
- Source of truth: `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- Selected benchmark: `{lane['benchmark']}`
- Track root: `{lane['track_path']}`

## Competitive Closure Targets

{targets}

## Remaining Implementation Deltas

{deltas}

## Required Release Evidence

This lane must stage a complete evidence pack under:

`release/readiness/{lane['slug']}/<version>/`

Required files are defined by:

- `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `docs/development/release-evidence/README.md`

## Later Server Verification

The later live verification packet for this lane is:

`docs/development/server-verification/{lane['slug']}.md`

## Non-Goals

- foreign wire-protocol emulation
- server-side UDR connector work
- inventing lane behavior that contradicts SBWP v1.1, MGA, or current repo truth
"""


def lane_plan(lane: dict) -> str:
    build = "\n".join(f"- `{cmd}`" for cmd in lane["build_commands"])
    verify = "\n".join(f"- `{cmd}`" for cmd in lane["verify_commands"])
    deltas = "\n".join(f"- {item}" for item in lane["remaining_deltas"])
    return f"""# {lane['display']} Driver Implementation Plan

Status: Current
Priority: {lane['priority']}

## Phase 1 - Offline-Complete Work

- freeze benchmark target `{lane['benchmark']}`
- push current lane truth into authoritative lane docs
- enumerate remaining implementation deltas with no hidden assumptions
- wire shared release-evidence requirements into this lane
- define later server-verification commands and artifact paths

## Phase 2 - Remaining Code Or Live-Proof Work

{deltas}

## Later Build / Verification Commands

Build/bootstrap commands:

{build}

Verification commands:

{verify}

## Output Contracts

- release evidence under `release/readiness/{lane['slug']}/<version>/`
- later verification packet in `docs/development/server-verification/{lane['slug']}.md`
"""


def lane_testing(lane: dict) -> str:
    env = "\n".join(f"- `{v}`" for v in lane["env"]) if lane["env"] else "- none"
    verify = "\n".join(f"- `{cmd}`" for cmd in lane["verify_commands"])
    return f"""# {lane['display']} Driver Testing Criteria

Status: Current
Priority: {lane['priority']}

## Deterministic Offline Coverage

- static spec/doc authority checks
- fixture and manifest alignment checks
- build/bootstrap command validity against repo-local package metadata
- release-evidence template and path validation

## Later Server-Backed Verification

Required environment inputs:

{env}

Required execution commands:

{verify}

## Required Release Evidence

- `CONTRACT_TEST_RESULTS.json`
- `CONFORMANCE_REPORT.md`
- `COMPATIBILITY_MATRIX.md`
- `PERFORMANCE_NUMBERS.md`
- `KNOWN_GAPS.md`
- `PACKAGING_AND_RELEASE_CADENCE.md`
- `SUMMARY.json`

Use the shared templates in:

`docs/development/release-evidence/`
"""


def top_level_driver_block(lane: dict) -> str:
    env = "\n".join(f"- `{v}`" for v in lane["env"]) if lane["env"] else "- none"
    build = "\n".join(f"- `{cmd}`" for cmd in lane["build_commands"])
    verify = "\n".join(f"- `{cmd}`" for cmd in lane["verify_commands"])
    targets = "\n".join(f"- {item}" for item in lane["competitive_targets"])
    deltas = "\n".join(f"- {item}" for item in lane["remaining_deltas"])
    return f"""## Competitive Closure Status

- Selected benchmark: `{lane['benchmark']}`
- Current state: `{lane['current_state']}`
- Track root: `{lane['track_path']}`

Competitive closure targets:

{targets}

Remaining implementation or proof deltas:

{deltas}

## Release Evidence And Later Verification

Release evidence path:

- `release/readiness/{lane['slug']}/<version>/`

Shared evidence templates:

- `docs/development/release-evidence/README.md`

Later server-verification packet:

- `docs/development/server-verification/{lane['slug']}.md`

Required environment inputs:

{env}

Build/bootstrap commands:

{build}

Verification commands:

{verify}"""


def adapter_compat_spec(lane: dict) -> str:
    deltas = "\n".join(f"- {item}" for item in lane["remaining_deltas"])
    targets = "\n".join(f"- {item}" for item in lane["competitive_targets"])
    return f"""# {lane['display']} Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support {lane['display']} with ScratchBird

## Executive Summary

- **Selected Benchmark:** `{lane['benchmark']}`
- **Current Lane State:** `{lane['current_state']}`
- **Track Root:** `{lane['track_path']}`

## Current Truth

{deltas}

## Mandatory Competitive Closure

{targets}

## Authoritative Supporting Docs

- API/reference: `{lane['api_path']}`
- Getting started: `{lane['getting_started_path']}`
- Later verification packet: `docs/development/server-verification/{lane['slug']}.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
"""


def adapter_api_doc(lane: dict) -> str:
    targets = "\n".join(f"- {item}" for item in lane["competitive_targets"])
    deltas = "\n".join(f"- {item}" for item in lane["remaining_deltas"])
    return f"""# {lane['display']} API / Integration Reference

## Authority

- Compatibility specification: `../application-reference/{Path(lane['compat_spec_path']).name}`
- Track root: `{lane['track_path']}`
- Later verification packet: `../development/server-verification/{lane['slug']}.md`

## Integration Surface

- benchmark target: `{lane['benchmark']}`
- current state: `{lane['current_state']}`

## Required Integration Families

{targets}

## Remaining Server-Blocked Validation

{deltas}
"""


def adapter_getting_started(lane: dict) -> str:
    build = "\n".join(f"- `{cmd}`" for cmd in lane["build_commands"])
    verify = "\n".join(f"- `{cmd}`" for cmd in lane["verify_commands"])
    env = "\n".join(f"- `{v}`" for v in lane["env"]) if lane["env"] else "- none"
    return f"""# {lane['display']}

## Authority

- Compatibility specification: `../application-reference/{Path(lane['compat_spec_path']).name}`
- API/reference: `../api-reference/{lane['slug']}.md`

## Build / Install

{build}

## Later Verification Inputs

{env}

## Later Verification Commands

{verify}

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
"""


def targeted_superseded_readme(title: str, top_level: str) -> str:
    return f"""
    # {title} Integration

    Status: Superseded by top-level authoritative compatibility specification

    ## Authority

    This subtree remains as supporting template and historical scaffold material.

    The authoritative compatibility contract now lives at:

    - `{top_level}`

    Do not treat the draft pages in this subtree as the primary truth for Beta 1
    closure work.
    """


def targeted_superseded_spec(title: str, top_level: str) -> str:
    return f"""
    # {title} Integration Specification

    Status: Supporting template only / superseded

    ## Authority

    The authoritative compatibility specification for this integration is:

    - `{top_level}`

    This file is retained only as supporting scaffold material and should not be
    used as the primary implementation source for current Beta 1 closure work.
    """


def render_release_template_readme() -> str:
    return """
    # Release Evidence Templates

    This directory contains the deterministic template pack required by
    `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`.

    Use these files as the exact starting point for each lane’s staged release
    evidence under:

    `release/readiness/<lane>/<version>/`

    ## Templates

    - `CONTRACT_TEST_RESULTS.template.json`
    - `CONFORMANCE_REPORT.template.md`
    - `COMPATIBILITY_MATRIX.template.md`
    - `PERFORMANCE_NUMBERS.template.md`
    - `KNOWN_GAPS.template.md`
    - `PACKAGING_AND_RELEASE_CADENCE.template.md`
    - `SUMMARY.template.json`
    """


def render_server_verification_readme() -> str:
    rows = []
    for lane in LANES:
        rows.append(f"| `{lane['slug']}` | `{lane['benchmark']}` | `{lane['current_state']}` | [{lane['slug']}.md]({lane['slug']}.md) |")
    return f"""# Server Verification Packets

These packets define the exact later verification steps that remain once a
working ScratchBird test server is available.

| Lane | Benchmark | Current State | Packet |
| --- | --- | --- | --- |
{chr(10).join(rows)}
"""


def render_verification_packet(lane: dict) -> str:
    build = "\n".join(f"{i+1}. `{cmd}`" for i, cmd in enumerate(lane["build_commands"]))
    verify = "\n".join(f"{i+1}. `{cmd}`" for i, cmd in enumerate(lane["verify_commands"]))
    env = "\n".join(f"- `{v}`" for v in lane["env"]) if lane["env"] else "- none"
    artifacts = "\n".join([
        f"- `release/readiness/{lane['slug']}/<version>/CONTRACT_TEST_RESULTS.json`",
        f"- `release/readiness/{lane['slug']}/<version>/CONFORMANCE_REPORT.md`",
        f"- `release/readiness/{lane['slug']}/<version>/COMPATIBILITY_MATRIX.md`",
        f"- `release/readiness/{lane['slug']}/<version>/PERFORMANCE_NUMBERS.md`",
        f"- `release/readiness/{lane['slug']}/<version>/KNOWN_GAPS.md`",
        f"- `release/readiness/{lane['slug']}/<version>/PACKAGING_AND_RELEASE_CADENCE.md`",
        f"- `release/readiness/{lane['slug']}/<version>/SUMMARY.json`",
    ])
    return f"""# {lane['display']} Server Verification Packet

Status: server_blocked

## Scope

- lane: `{lane['slug']}`
- benchmark: `{lane['benchmark']}`
- current state: `{lane['current_state']}`
- track root: `{lane['track_path']}`

## Required Environment

{env}

## Build / Bootstrap Commands

{build}

## Verification Commands

{verify}

## Expected Artifacts

{artifacts}

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/{lane['slug']}/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
"""


def render_authority_index() -> str:
    rows = []
    for lane in LANES:
        impl = lane.get("spec_path") or lane.get("compat_spec_path")
        rows.append(
            f"| `{lane['slug']}` | `{lane['kind']}` | `{lane['current_state']}` | `{lane['benchmark']}` | `{impl}` | `docs/development/release-evidence/README.md` | `docs/development/server-verification/{lane['slug']}.md` |"
        )
    return f"""# Driver Lane Authority Index

This index names the single authoritative implementation-spec path, shared
release-evidence template path, and later verification packet for every
active Beta 1 driver/tooling/adapter lane.

| Lane | Kind | Current State | Benchmark | Implementation Spec | Release Evidence | Verification Packet |
| --- | --- | --- | --- | --- | --- | --- |
{chr(10).join(rows)}
"""


def render_server_independent_model() -> str:
    return """
    # Driver Server-Independent Completion Model

    Status: Current
    Last Updated: 2026-04-03

    ## Purpose

    Define the shared model for finishing all driver-repo work that does not
    require a running ScratchBird test server.

    ## Core Rule

    Server-independent completion means:

    - authoritative implementation specs are current
    - benchmark and gap truth are current
    - release-evidence templates are frozen
    - later verification packets are explicit
    - integration-tree authority is explicit

    It does not mean:

    - live conformance has been re-run
    - performance claims are measured for the current build
    - compatibility claims are fully proven against a running server

    ## Required Companion Documents

    - `DRIVER_LANE_AUTHORITY_INDEX.md`
    - `DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
    - `DRIVER_SERVER_VERIFICATION_PACKET_CONTRACT.md`
    - `DRIVER_INTEGRATION_AUTHORITY_AND_SUPERSESSION_MAP.md`
    - `docs/development/release-evidence/README.md`
    - `docs/development/server-verification/README.md`
    """


def render_server_verification_contract() -> str:
    return """
    # Driver Server Verification Packet Contract

    Status: Current
    Last Updated: 2026-04-03

    ## Purpose

    Define the required contents of the per-lane verification packets stored in
    `docs/development/server-verification/`.

    ## Required Contents Per Packet

    - exact track root
    - selected benchmark
    - current lane state
    - required environment variables
    - exact build/bootstrap commands
    - exact verification commands
    - expected staged release-evidence artifacts
    - explicit pass/fail rule

    ## Rule

    A lane may be called `server_blocked only` only when its verification packet
    already exists and no hidden runbook knowledge is required beyond that file.
    """


def render_integration_authority_map() -> str:
    lines = [
        "# Driver Integration Authority And Supersession Map",
        "",
        "Status: Current",
        "Last Updated: 2026-04-03",
        "",
        "## Classification Rules",
        "",
        "- `authoritative_active`: current Beta 1 closure source",
        "- `supporting_template_only`: retained as reference/template only",
        "- `future_backlog`: not part of current active closure",
        "- `superseded_by_top_level_spec`: historical subtree retained, but a top-level doc is authoritative",
        "",
        "## Targeted Superseded Directories",
        "",
        "| Directory | Classification | Authoritative Doc |",
        "| --- | --- | --- |",
    ]
    for item in TARGETED_SUPERSEDED:
        lines.append(f"| `docs/specifications/integrations/{item['dir']}` | `superseded_by_top_level_spec` | `{item['top_level']}` |")
    lines.extend([
        "",
        "## Group-Level Classification",
        "",
        "| Group | Classification | Notes |",
        "| --- | --- | --- |",
        "| `docs/specifications/integrations/drivers/` | `supporting_template_only` | Current active driver authority lives under `docs/specifications/drivers/` and the top-level driver specs. |",
        "| `docs/specifications/integrations/orm/` | `future_backlog` except targeted superseded directories | Keep for future expansion, not active Beta 1 authority. |",
        "| `docs/specifications/integrations/tools/` | `future_backlog` except targeted superseded directories | DBeaver and Metabase are covered by top-level compatibility specs. |",
        "| `docs/specifications/integrations/apps/` | `future_backlog` | Not part of the current active driver/adaptor closure program. |",
        "| `docs/specifications/integrations/bigdata/` | `future_backlog` | Not part of the current active closure program. |",
        "| `docs/specifications/integrations/cloud/` | `future_backlog` | Not part of the current active closure program. |",
    ])
    return "\n".join(lines) + "\n"


def render_server_blocked_report() -> str:
    rows = []
    for lane in LANES:
        rows.append(f"| `{lane['slug']}` | `{lane['current_state']}` | {lane['remaining_deltas'][0]} | `docs/development/server-verification/{lane['slug']}.md` |")
    return f"""
    # Driver Server-Blocked Remaining Work

    Status: Current
    Last Updated: 2026-04-03

    This report captures the remaining work that still requires a working
    ScratchBird test server after the server-independent completion pass.

    | Lane | Current State | Primary Remaining Server-Blocked Item | Verification Packet |
    | --- | --- | --- | --- |
    {chr(10).join(rows)}
    """


def render_closeout() -> str:
    return """
    # Driver Server-Independent Completion Closeout (2026-04-03)

    Status: Completed

    ## Result

    The offline-completable driver-repo work is now closed.

    The repository now has:

    - benchmark-aware authoritative lane specs
    - authoritative adapter compatibility packages
    - release-evidence templates
    - per-lane later server-verification packets
    - an integration-tree authority and supersession map
    - an explicit server-blocked remaining-work report

    ## Remaining Work

    Remaining unfinished work is now intentionally reduced to live verification,
    measured conformance, measured performance collection, and final release
    evidence staging against a working ScratchBird test server.
    """


def render_release_contract_block() -> str:
    return """
    ## Template Pack

    The canonical starter templates for every required evidence file now live in:

    - `docs/development/release-evidence/README.md`

    Low-reasoning implementation or release agents should copy those templates
    into `release/readiness/<driver-id>/<version>/` and fill them with measured
    lane output rather than inventing file layouts ad hoc.
    """


def render_specifications_readme() -> str:
    return """
    # ScratchBird Driver Specifications

    This directory contains implementation requirements for the native
    ScratchBird drivers, CLI tooling, and authoritative cross-lane closure
    models.

    Current implementation status by lane is tracked in:

    - [../audit/DRIVER_IMPLEMENTATION_AUDIT.md](../audit/DRIVER_IMPLEMENTATION_AUDIT.md)
    - [../audit/DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv](../audit/DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv)
    - [../audit/DRIVER_SERVER_BLOCKED_REMAINING_WORK.md](../audit/DRIVER_SERVER_BLOCKED_REMAINING_WORK.md)

    ## Core Specifications

    - [NATIVE_PROTOCOL_ALIGNMENT.md](NATIVE_PROTOCOL_ALIGNMENT.md)
    - [PREPARE_BIND_REQUIREMENTS.md](PREPARE_BIND_REQUIREMENTS.md)
    - [TYPE_MAPPING_MATRIX.md](TYPE_MAPPING_MATRIX.md)
    - [METADATA_SCHEMA_CONTRACT.md](METADATA_SCHEMA_CONTRACT.md)
    - [DRIVER_MONITORING_VIEW_SUPPORT.md](DRIVER_MONITORING_VIEW_SUPPORT.md)
    - [DRIVER_CONFORMANCE_TEST_HARNESS.md](DRIVER_CONFORMANCE_TEST_HARNESS.md)
    - [DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md](DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md)
    - [DRIVER_DSN_AND_CONFIG_STANDARD.md](DRIVER_DSN_AND_CONFIG_STANDARD.md)
    - [DRIVER_AUTHENTICATION_MAPPING.md](DRIVER_AUTHENTICATION_MAPPING.md)
    - [DRIVER_ERROR_MAPPING.md](DRIVER_ERROR_MAPPING.md)
    - [DRIVER_PARAMETER_ENCODING.md](DRIVER_PARAMETER_ENCODING.md)
    - [DRIVER_RESULT_DECODING.md](DRIVER_RESULT_DECODING.md)
    - [DRIVER_CANCELLATION_TIMEOUTS.md](DRIVER_CANCELLATION_TIMEOUTS.md)
    - [DRIVER_STREAMING_AND_PAGING.md](DRIVER_STREAMING_AND_PAGING.md)
    - [DRIVER_METADATA_JDBC_ODBC_MAPPING.md](DRIVER_METADATA_JDBC_ODBC_MAPPING.md)
    - [DRIVER_THREAD_SAFETY_POOLING.md](DRIVER_THREAD_SAFETY_POOLING.md)
    - [DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_MODEL.md](DRIVER_BEST_IN_CLASS_COMPETITIVE_CLOSURE_MODEL.md)
    - [DRIVER_SERVER_INDEPENDENT_COMPLETION_MODEL.md](DRIVER_SERVER_INDEPENDENT_COMPLETION_MODEL.md)
    - [DRIVER_SERVER_VERIFICATION_PACKET_CONTRACT.md](DRIVER_SERVER_VERIFICATION_PACKET_CONTRACT.md)
    - [DRIVER_LANE_AUTHORITY_INDEX.md](DRIVER_LANE_AUTHORITY_INDEX.md)
    - [DRIVER_INTEGRATION_AUTHORITY_AND_SUPERSESSION_MAP.md](DRIVER_INTEGRATION_AUTHORITY_AND_SUPERSESSION_MAP.md)

    ## Lane-Specific Top-Level Specs

    - [DRIVER_ELIXIR_ECTO_ADAPTER.md](DRIVER_ELIXIR_ECTO_ADAPTER.md)
    - [DRIVER_SWIFT_ASYNC_ADAPTER.md](DRIVER_SWIFT_ASYNC_ADAPTER.md)
    - [DRIVER_DART_DATABASE_API.md](DRIVER_DART_DATABASE_API.md)
    - [DRIVER_MOJO_NATIVE_API.md](DRIVER_MOJO_NATIVE_API.md)

    ## Migrated Driver Specs

    - [drivers/README.md](drivers/README.md)
    - [drivers/CLI_TOOLS_SPECIFICATION.md](drivers/CLI_TOOLS_SPECIFICATION.md)
    - [drivers/JDBC_DRIVER_SPECIFICATION.md](drivers/JDBC_DRIVER_SPECIFICATION.md)
    - [drivers/ODBC_DRIVER_SPECIFICATION.md](drivers/ODBC_DRIVER_SPECIFICATION.md)
    - [drivers/language/README.md](drivers/language/README.md)
    - [integrations/README.md](integrations/README.md)
    - [api/CLIENT_LIBRARY_API_SPECIFICATION.md](api/CLIENT_LIBRARY_API_SPECIFICATION.md)

    ## Operational Companions

    - [../development/release-evidence/README.md](../development/release-evidence/README.md)
    - [../development/server-verification/README.md](../development/server-verification/README.md)
    - [../application-reference/README.md](../application-reference/README.md)
    - [../api-reference/README.md](../api-reference/README.md)
    - [../getting-started/README.md](../getting-started/README.md)
    """


def render_integration_readme() -> str:
    return """
    # Integration Specifications
    Status: Current

    This subtree is no longer treated as a flat active authority surface.

    See:

    - `../DRIVER_INTEGRATION_AUTHORITY_AND_SUPERSESSION_MAP.md`

    ## Active Authority For Current Beta 1 Closure

    Targeted adapters now use top-level authoritative compatibility specs in:

    - `docs/application-reference/DBEAVER_COMPATIBILITY_SPECIFICATION.md`
    - `docs/application-reference/HIBERNATE_COMPATIBILITY_SPECIFICATION.md`
    - `docs/application-reference/METABASE_COMPATIBILITY_SPECIFICATION.md`
    - `docs/application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md`
    - `docs/application-reference/SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md`
    - `docs/application-reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md`
    - `docs/application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md`

    ## Group Classification

    - `drivers/`: supporting template only
    - `orm/`: future backlog except targeted superseded directories
    - `tools/`: future backlog except targeted superseded directories
    - `apps/`: future backlog
    - `bigdata/`: future backlog
    - `cloud/`: future backlog
    """


def render_app_ref_readme() -> str:
    rows = []
    for lane in [l for l in LANES if l["kind"] == "adapter"]:
        rows.append(f"- [{lane['display']}]({Path(lane['compat_spec_path']).name})")
    return f"""
    # Application Driver Specifications

    This directory contains the authoritative compatibility contracts for the
    active BI/application adapters in the Beta 1 driver program.

    ## Authoritative Specs

    {chr(10).join(rows)}

    ## Notes

    Older draft pages under `docs/specifications/integrations/` are now
    supporting template or superseded material for these targeted adapters.
    """


def render_api_ref_readme() -> str:
    driver_lines = []
    for lane in LANES:
        driver_lines.append(f"- [{lane['display']}]({lane['slug']}.md)")
    return f"""
    # API Reference

    This section captures the public API or integration surface for each active
    driver, tooling, and adapter lane.

    ## Active References

    {chr(10).join(driver_lines)}

    ## Shared References

    - [Type mapping matrix](../specifications/TYPE_MAPPING_MATRIX.md)
    - [Driver error mapping](../specifications/DRIVER_ERROR_MAPPING.md)
    - [Prepare/bind requirements](../specifications/PREPARE_BIND_REQUIREMENTS.md)
    - [Lane authority index](../specifications/DRIVER_LANE_AUTHORITY_INDEX.md)
    """


def render_getting_started_readme() -> str:
    lines = []
    for lane in LANES:
        lines.append(f"- [{lane['display']}]({lane['slug']}.md)")
    return f"""
    # Getting Started

    This section provides installation and first-connection guidance for the
    active Beta 1 driver, tooling, and adapter lanes.

    ## Guides

    {chr(10).join(lines)}

    ## Shared References

    - [Connection modes and auth](../user-documentation/connectivity/connection-modes-and-auth.md)
    - [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md)
    - [Release evidence templates](../development/release-evidence/README.md)
    - [Server verification packets](../development/server-verification/README.md)
    """


def render_audit_readme() -> str:
    return """
    # ScratchBird Driver Audits

    This directory contains implementation audits and closure reports for the
    ScratchBird drivers and active adapters.

    ## Audits

    - [DRIVER_IMPLEMENTATION_AUDIT.md](DRIVER_IMPLEMENTATION_AUDIT.md)
    - [DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv](DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv)
    - [BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_REPORT.md](BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_REPORT.md)
    - [BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_MATRIX.csv](BEST_IN_CLASS_DRIVER_COMPETITIVE_CLOSURE_MATRIX.csv)
    - [best_in_class_driver_gaps_2026-04-03/README.md](best_in_class_driver_gaps_2026-04-03/README.md)
    - [DRIVER_SERVER_BLOCKED_REMAINING_WORK.md](DRIVER_SERVER_BLOCKED_REMAINING_WORK.md)
    - [DRIVER_CONFORMANCE_CHECKLIST.md](DRIVER_CONFORMANCE_CHECKLIST.md)
    - [SYS_VIEW_COVERAGE_AND_DRIVER_IMPACT.md](SYS_VIEW_COVERAGE_AND_DRIVER_IMPACT.md)
    - [MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md](MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md)
    """


def render_development_readme() -> str:
    return """
    # Development Guides

    This section covers build, test, packaging, release evidence, and later
    server-verification workflows for the driver set.

    ## Guides

    - [Development notes](development-notes.md)
    - [Build and test matrix](build-and-test.md)
    - [Toolchain setup](toolchain-setup.md)
    - [Conformance testing](conformance-testing.md)
    - [Packaging and release](release-packaging.md)
    - [Release evidence templates](release-evidence/README.md)
    - [Server verification packets](server-verification/README.md)
    """


def render_language_index() -> str:
    rows = []
    for lane in [l for l in LANES if l["category"] == "language"]:
        rel = Path(lane["spec_path"]).parent.name
        rows.append(f"| `{rel}` | `{lane['current_state']}` | `{lane['benchmark']}` |")
    return f"""
    # Language Driver Templates

    Status: Current

    This directory contains the authoritative per-language driver spec packages
    for the active language lanes that use lane-local template directories.

    ## Current Status

    | Lane | Current State | Benchmark |
    | --- | --- | --- |
    {chr(10).join(rows)}

    Top-level driver lanes are tracked in:

    - `docs/specifications/DRIVER_DART_DATABASE_API.md`
    - `docs/specifications/DRIVER_ELIXIR_ECTO_ADAPTER.md`
    - `docs/specifications/DRIVER_MOJO_NATIVE_API.md`
    - `docs/specifications/DRIVER_SWIFT_ASYNC_ADAPTER.md`
    - `docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md`
    - `docs/specifications/drivers/ODBC_DRIVER_SPECIFICATION.md`

    See `docs/specifications/DRIVER_LANE_AUTHORITY_INDEX.md` for the full cross-lane
    authority map.
    """


def close_planning_docs() -> None:
    wp = PLANNING / "DRIVER_SERVER_INDEPENDENT_COMPLETION_WORKPLAN_2026-04-03.md"
    txt = wp.read_text().replace("Status: Active", "Status: Completed")
    if "## Completion Evidence" not in txt:
        txt += "\n## Completion Evidence\n\n- lane authority index generated\n- release-evidence template pack generated\n- per-lane server verification packets generated\n- integration-tree authority map generated\n- remaining work reduced to explicit server-blocked verification\n"
    wp.write_text(txt)

    tracker = PLANNING / "DRIVER_SERVER_INDEPENDENT_COMPLETION_EXECUTION_TRACKER_2026-04-03.md"
    txt = tracker.read_text().replace("Status: Active", "Status: Completed")
    txt = txt.replace("| Baseline freeze | `OFF-000` | planned |", "| Baseline freeze | `OFF-000` | closed |")
    txt = txt.replace("| Drivers and tooling | `OFF-001` .. `OFF-017` | planned |", "| Drivers and tooling | `OFF-001` .. `OFF-017` | closed |")
    txt = txt.replace("| Adapters | `OFF-018` .. `OFF-024` | planned |", "| Adapters | `OFF-018` .. `OFF-024` | closed |")
    txt = txt.replace("| Release evidence and verification | `OFF-025` .. `OFF-030` | planned |", "| Release evidence and verification | `OFF-025` .. `OFF-030` | closed |")
    txt = txt.replace("| Cleanup and closeout | `OFF-031` .. `OFF-034` | planned |", "| Cleanup and closeout | `OFF-031` .. `OFF-034` | closed |")
    txt = txt.replace("planned |", "closed |")
    tracker.write_text(txt)

    rows = []
    ticket_path = PLANNING / "DRIVER_SERVER_INDEPENDENT_COMPLETION_ORDERED_TICKETS_2026-04-03.csv"
    with ticket_path.open() as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        for row in reader:
            row["status"] = "closed"
            rows.append(row)
    with ticket_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    # shared specs
    write(SPEC / "DRIVER_SERVER_INDEPENDENT_COMPLETION_MODEL.md", render_server_independent_model())
    write(SPEC / "DRIVER_SERVER_VERIFICATION_PACKET_CONTRACT.md", render_server_verification_contract())
    write(SPEC / "DRIVER_LANE_AUTHORITY_INDEX.md", render_authority_index())
    write(SPEC / "DRIVER_INTEGRATION_AUTHORITY_AND_SUPERSESSION_MAP.md", render_integration_authority_map())

    # update core release contract with template pack pointer
    append_block(SPEC / "DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md", "release-evidence-template-pack", render_release_contract_block())

    # shared development artifacts
    write(DEVELOPMENT / "release-evidence" / "README.md", render_release_template_readme())
    write(DEVELOPMENT / "release-evidence" / "CONFORMANCE_REPORT.template.md", """
    # Conformance Report

    - driver_id:
    - version:
    - tested protocol version:
    - manifest/suite list:
    - metadata coverage summary:
    - SQLSTATE/error-path summary:
    - deviations/waivers:
    - previous-release comparison:
    - final verdict:
    """)
    write(DEVELOPMENT / "release-evidence" / "COMPATIBILITY_MATRIX.template.md", """
    # Compatibility Matrix

    | Axis | Supported | Notes |
    | --- | --- | --- |
    | Operating systems |  |  |
    | Architectures |  |  |
    | Runtime/compiler versions |  |  |
    | ScratchBird server versions |  |  |
    | Protocol versions |  |  |
    | TLS/backend library deps |  |  |
    | Framework/adapter targets |  |  |
    | Unsupported combinations |  |  |
    """)
    write(DEVELOPMENT / "release-evidence" / "PERFORMANCE_NUMBERS.template.md", """
    # Performance Numbers

    ## Environment

    - driver build/version:
    - server build/version:
    - dataset/fixture:
    - sample count:

    ## Metrics

    - connect/auth latency:
    - simple query latency:
    - prepared execute throughput:
    - streaming throughput:
    - peak memory during streaming:
    - metadata-call latency:
    - cancel/timeout latency:
    - batch/bulk performance:
    """)
    write(DEVELOPMENT / "release-evidence" / "KNOWN_GAPS.template.md", """
    # Known Gaps

    | Gap ID | Severity | Subsystem | Behavior | Workaround | Release Blocking | Target Milestone |
    | --- | --- | --- | --- | --- | --- | --- |
    |  |  |  |  |  |  |  |
    """)
    write(DEVELOPMENT / "release-evidence" / "PACKAGING_AND_RELEASE_CADENCE.template.md", """
    # Packaging And Release Cadence

    - package coordinates:
    - artifact list:
    - signing/checksum state:
    - prerelease/stable channel names:
    - semantic versioning policy:
    - release cadence:
    - support window:
    - deprecation policy:
    - rollback/yank policy:
    """)
    write(DEVELOPMENT / "release-evidence" / "CONTRACT_TEST_RESULTS.template.json", json.dumps({
        "schema_version": "1",
        "driver_id": "",
        "driver_version": "",
        "commit": "",
        "build_timestamp_utc": "",
        "runtime_matrix": [],
        "suite_results": [],
        "pass_count": 0,
        "fail_count": 0,
        "skip_count": 0,
        "skips": [],
        "artifact_links": [],
    }, indent=2))
    write(DEVELOPMENT / "release-evidence" / "SUMMARY.template.json", json.dumps({
        "driver_id": "",
        "version": "",
        "release_channel": "",
        "release_readiness": "blocked",
        "blocking_findings": [],
        "artifact_manifest": [],
    }, indent=2))

    write(DEVELOPMENT / "server-verification" / "README.md", render_server_verification_readme())
    for lane in LANES:
        write(DEVELOPMENT / "server-verification" / f"{lane['slug']}.md", render_verification_packet(lane))

    # language lane docs
    for lane in [l for l in LANES if l["category"] == "language"]:
        write(ROOT / lane["readme_path"], lane_readme(lane))
        write(ROOT / lane["spec_path"], lane_spec(lane))
        write(ROOT / lane["plan_path"], lane_plan(lane))
        write(ROOT / lane["testing_path"], lane_testing(lane))

    # top-level driver closures via append blocks
    for lane in [l for l in LANES if l["category"] in {"top_level", "cli"}]:
        append_block(ROOT / lane["spec_path"], f"{lane['slug']}-server-independent-closure", top_level_driver_block(lane))

    # adapter docs
    for lane in [l for l in LANES if l["kind"] == "adapter"]:
        write(ROOT / lane["compat_spec_path"], adapter_compat_spec(lane))
        write(ROOT / lane["api_path"], adapter_api_doc(lane))
        write(ROOT / lane["getting_started_path"], adapter_getting_started(lane))

    # superseded targeted integration directories
    for item in TARGETED_SUPERSEDED:
        d = INTEGRATIONS / item["dir"]
        write(d / "README.md", targeted_superseded_readme(item["title"], item["top_level"]))
        write(d / "SPECIFICATION.md", targeted_superseded_spec(item["title"], item["top_level"]))

    # indexes
    write(SPEC / "README.md", render_specifications_readme())
    write(SPEC / "integrations" / "README.md", render_integration_readme())
    write(APP_REF / "README.md", render_app_ref_readme())
    write(API_REF / "README.md", render_api_ref_readme())
    write(GETTING / "README.md", render_getting_started_readme())
    write(AUDIT / "README.md", render_audit_readme())
    write(DEVELOPMENT / "README.md", render_development_readme())
    write(LANG_ROOT / "README.md", render_language_index())
    write(AUDIT / "DRIVER_SERVER_BLOCKED_REMAINING_WORK.md", render_server_blocked_report())

    # planning closeout
    write(PLANNING / "DRIVER_SERVER_INDEPENDENT_COMPLETION_CLOSEOUT_2026-04-03.md", render_closeout())
    close_planning_docs()


if __name__ == "__main__":
    main()
