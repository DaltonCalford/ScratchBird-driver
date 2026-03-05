# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

---

## Project Status

ScratchBird-driver is in **Initial Early Beta (`0.1.0`)**.

All released drivers implement the **ScratchBird Wire Protocol (SBWP v1.1)** baseline handshake and core execution path. However, feature completeness varies significantly by language lane. This README reflects the current audited capability state across drivers.

**Parent Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)  
**Release Targets:** `docs/planning/RELEASE_TARGETS.md`

---

## Capability Model

Each driver is evaluated across the following capability groups:

- **CONN** – Connection lifecycle, TLS enforcement, auth, manager-proxy
- **TXN** – Transaction semantics (autocommit mapping, savepoints)
- **EXEC** – Query execution (prepare/bind/execute, streaming, multi-result)
- **META** – Metadata surfaces (sys.* alignment, schema helpers)
- **TYPE** – Type encode/decode coverage
- **ERR** – Error mapping and SQLSTATE alignment
- **RES** – Resource lifecycle (cursors, statements, pooling, cleanup)

Legend:

- ✅ Implemented (baseline-complete for 0.1.0 scope)
- 🟡 Partial (usable but missing parity elements or integration depth)
- 🔴 Gap (explicitly incomplete or missing surface)

---

# Driver Capability Matrix (Audit Snapshot: 2026-03-05)

## Alpha Drivers

| Driver | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State |
|--------|------|-----|------|------|------|-----|-----|--------------|
| **Java / JDBC** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Most complete lane |
| **ODBC 3.8** | ✅ | ✅ | ✅ | 🟡 | ✅ | ✅ | ✅ | Near-complete baseline, metadata family parity remains |
| **.NET** | ✅ | 🟡 | ✅ | 🟡 | 🟡 | ✅ | ✅ | CONN/EXEC/ERR/RES implemented; TXN/META/TYPE breadth and live-depth remain partial |
| **Node.js** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | CONN/ERR/RES implemented; TXN/EXEC/META/TYPE remain partial pending broader live-depth |
| **Python** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ERR/RES implemented; CONN/TXN/EXEC/META/TYPE remain partial pending broader live-depth |
| **Go** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ERR/RES implemented; CONN/TXN/EXEC/META/TYPE remain partial pending broader live-depth |
| **Rust** | 🟡 | 🟡 | ✅ | 🟡 | ✅ | ✅ | ✅ | Strong core; EXEC parity implemented, remaining depth in CONN/TXN/META |
| **Ruby** | 🟡 | 🟡 | ✅ | 🟡 | 🟡 | ✅ | ✅ | EXEC/ERR/RES are implemented with deterministic lane tests; CONN/TXN/META/TYPE integration depth remains |
| **PHP** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ERR/RES implemented with expanded lane tests; CONN/TXN/EXEC/META/TYPE remain partial |
| **Pascal** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ERR/RES implemented with deterministic lane tests; CONN/TXN/EXEC/META/TYPE remain partial |
| **Mojo** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Mojo-native SBWP lane with expanded metadata parity scaffolding (multi-restriction, wildcard escape/null handling, alias-family restriction mapping); TXN/EXEC/META/TYPE/ERR/RES remain partial pending full native transport cutover |

---

## Beta Drivers

| Driver | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State |
|--------|------|-----|------|------|------|-----|-----|--------------|
| **C/C++ (libscratchbird_client)** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Strong C API base, transport gaps |
| **R (DBI)** | 🟡 | 🟡 | ✅ | 🟡 | ✅ | ✅ | 🟡 | Execution/type/error parity is strongest; CONN/TXN/META/RES depth remains in progress |
| **Swift (Async/Await)** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | CONN implemented with expanding deterministic parity tests; broader live integration remains pending |
| **Dart** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | CONN implemented; TYPE/ERR parity significantly expanded (typed exceptions + SQLSTATE parsing/mapping), with direct + manager-proxy integration scaffolding now in place; broader live runtime depth remains pending |

---

## Recent Driver Progress (2026-03-05)

- **Dart lane:** Added connection-policy rejection parity tests (`sslmode=disable`, `binary_transfer=false`, `compression=zstd`) and aligned checklist/mapping artifacts.
- **Dart lane:** Expanded type decode and negative-path coverage (core scalar decode paths, text-vs-unknown behavior, range/composite guardrails, unsupported-type checks).
- **Dart lane:** Added env-gated integration suite for direct and manager-proxy connection paths (`SCRATCHBIRD_TEST_DSN`, `SCRATCHBIRD_TEST_MANAGER_DSN`) covering query, transaction lifecycle, metadata wrappers, and JSON/JSONB roundtrips.
- **Dart lane:** Introduced typed driver exception hierarchy and structured server error parsing with SQLSTATE/code propagation + SQLSTATE class-based mapping.
- **Python lane:** Continued JDBC parity hardening for type decode semantics (temporal/unknown/binary edge cases) with expanded deterministic tests and updated lane baseline artifacts.
- **Mojo lane:** Expanded restriction-aware metadata query shaping across native/facade/shim execution surfaces, including multi-restriction composition helpers and deterministic rowcount wrappers.
- **Mojo lane:** Added wildcard/escape and null-aware metadata restriction semantics (`LIKE ... ESCAPE '\\'`, `IS NULL`) with deterministic smoke coverage in native bootstrap and facade tests.
- **Mojo lane:** Added broader metadata restriction alias-family support (`catalog`, `index`, `constraint`, `routine`, `type`) with expanded predicate coverage for schema/table/index/constraint/routine/type query families.
- **Mojo lane:** Extended integration smoke metadata checks with deterministic metadata stability and DDL payload contract assertions; synchronized Mojo lane README/checklist/baseline mapping artifacts.
- **Mojo lane:** Expanded integration smoke to cover transaction/savepoint lifecycle and prepare/stream-cancel recovery checks for direct and manager-proxy execution paths.
- **Mojo lane:** Added native-bootstrap DSN host/port parsing fields and deterministic native/facade auth-fail guard parity (`sb_test_auth_fail=true` → `28P01`) with smoke assertions.
- **Mojo lane:** Updated gated CI Mojo lane to run explicit native surface/bootstrap + metadata + integration + conformance sequence.
- **Mojo lane:** Added native timeout alias parsing/guard parity (`connect_timeout|connecttimeout`, `socket_timeout|sockettimeout`, `login_timeout|logintimeout`) plus `manager-proxy` normalization coverage in native/facade smoke lanes.
- **Mojo lane:** Fixed front-door mode source precedence (`front_door_mode` over `connection_mode`/`ingress_mode`) and expanded alias normalization coverage (`managerproxy`) in native/facade smoke tests.
- **Mojo lane:** Added native credential parsing/override coverage (`user`/`password`, including password-with-colon DSNs and host-only DSN query overrides) in native/facade smoke lanes.

---

## In Development

| Driver | Notes |
|--------|------|
| **Elixir (Ecto Adapter)** | Functional adapter, SCRAM + type layer present, but no full baseline mapping artifact yet. Considered in-development and not baseline-certified. |

---

## Ecosystem Adapter Status (Alpha Track)

| Adapter | Current State |
|--------|---------------|
| **Prisma adapter** | Deterministic adapter and contract suite implemented; runtime remains blocked by Prisma provider registration (`provider="scratchbird"` unsupported by stock Prisma CLI). |
| **SQLAlchemy dialect** | Deterministic dialect and ORM/reflection contract suite implemented; live runtime matrix is blocked in this shell by endpoint TLS posture mismatch. |
| **Hibernate dialect** | Deterministic dialect and contract suite implemented; runtime JDBC probe now passes with local JDBC jar auto-detected, while full JPA lifecycle/migration matrix remains pending. |
| **TypeORM adapter** | Deterministic adapter and contract suite implemented; runtime remains blocked because stock TypeORM does not recognize `type="scratchbird"` (driver registry gap). |

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages. These drivers target the ScratchBird native protocol (SBWP v1.1) and provide idiomatic APIs for each supported language.

Emulated protocols (PostgreSQL/MySQL/Firebird) are handled by their own native client drivers against ScratchBird's emulation listeners.

---

## Target Features (SBWP v1.1 Baseline)

All baseline drivers aim to implement:

- **Native Wire Protocol (SBWP v1.1)** – ScratchBird native protocol (port 3092)
- **TLS 1.3 Required** – No plaintext fallback
- **Server-side Prepare/Bind** – PARSE/BIND/EXECUTE for parameters
- **Transactions** – Always-in-transaction semantics with autocommit mapping
- **Type Mapping** – Full wire type coverage (including composite/geometry/range)
- **Binary-only parameters enforced**
- **`compression=zstd` rejected**

---

## Current Enterprise Readiness Tracking

Authoritative gap tracking lives in:

- `docs/planning/DRIVER_ENTERPRISE_READINESS_STRICT_IMPLEMENTATION_MATRIX_*.md`
- `docs/planning/DRIVER_ENTERPRISE_READINESS_REMAINING_GAPS_STRICT_*.md`
- `docs/planning/DRIVER_ENTERPRISE_READINESS_TICKETS_*.md`

This README provides a high-level executive summary. The planning documents remain the ticket-level source of truth.

---

## CLI Tools

| Tool | Purpose | Status |
|------|---------|--------|
| **sb_isql** | Native ScratchBird interactive shell | CONN ✅ / TXN 🟡 / EXEC ✅ / META 🟡 / TYPE 🟡 / ERR ✅ / RES 🟡 |
| **sb_admin** | Server administration CLI | Baseline implemented |
| **sb_backup** | Backup/restore CLI | Baseline implemented |
| **sb_security** | User/role management CLI | Baseline implemented |
| **sb_verify** | Database verification CLI | Baseline implemented |
| **sbdriver-conformance** | SBWP conformance adapter | CONN ✅ / TXN 🟡 / EXEC ✅ / META 🟡 / TYPE 🟡 / ERR ✅ / RES 🟡 (`txn_exec`/`res_loop_exec` parity and typed manifest assertions implemented; live DSN-backed matrix remains partial) |

FDW-based emulation CLI tools remain gated by engine-side adapters.

---

## Project Structure

```
ScratchBird-driver/
├── docs/
├── wiki/
├── tracks/alpha/drivers/cli/
├── tracks/beta/drivers/cpp/
├── tracks/alpha/drivers/odbc/
├── tracks/alpha/drivers/go/
├── tracks/alpha/drivers/python/
├── tracks/alpha/drivers/node/
├── tracks/alpha/drivers/ruby/
├── tracks/alpha/drivers/rust/
├── tracks/alpha/drivers/php/
├── tracks/beta/drivers/r/
├── tracks/alpha/drivers/pascal/
├── tracks/alpha/drivers/dotnet/
├── tracks/alpha/drivers/jdbc/
├── tracks/beta/drivers/dart/
├── tracks/beta/drivers/swift/
├── tracks/p3/drivers/elixir/
├── tracks/alpha/drivers/mojo/
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

---

## Documentation

- **Documentation Index:** `docs/README.md`
- **Getting Started:** `docs/getting-started/`
- **API Reference:** `docs/api-reference/`
- **Specifications:** `docs/specifications/`
- **Development Guides:** `docs/development/`

---

## Contributing

We welcome contributions. Please review `CONTRIBUTING.md` before submitting pull requests.

---

## License

Licensed under the Initial Developer's Public License (IDPL). See `LICENSE` for details.

---

**Last Updated:** 2026-03-05
