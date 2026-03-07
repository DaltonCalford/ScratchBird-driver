# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

---

## Project Status

ScratchBird-driver is in **Initial Early Beta (`1.0`)**.

All released drivers implement the **ScratchBird Wire Protocol (SBWP v1.1)** baseline handshake and core execution path. However, feature completeness varies significantly by language lane. This README reflects the current audited capability state across drivers.
All but one of the Alpha plan drivers are implemented, one Beta plan driver has been implemented

Implementation means full JDBC functionality/support in place.
Some drivers (.NET, PASCAL and C/C++) have extended enterprise level implementation - to meet the full .NET specification.

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

# Driver Capability Matrix (Audit Snapshot: 2026-03-06)

Mojo lane note: the prior 8-item JDBC-parity gap batch has been implemented in this audit cycle (hybrid parity path: native facade/bootstrap + opt-in wire bridge + matrixed runtime coverage).

## Alpha Drivers

| Driver          | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State                                                                                                                                                                                                                         |
| --------------- | ---- | --- | ---- | ---- | ---- | --- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Java / JDBC** | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Most complete lane                                                                                                                                                                                                                    |
| **ODBC 3.8**    | ✅    | ✅   | ✅    | 🟡   | ✅    | ✅   | ✅   | Near-complete baseline, metadata family parity remains                                                                                                                                                                                |
| **.NET**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Enterprise lane complete; sustained soak/fault harnesses and cross-runtime contract gate are implemented                                                                                                                              |
| **Node.js**     | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across TXN/EXEC/META/TYPE with expanded lane tests and env-gated live-depth checks                                                                                                                   |
| **Python**      | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with always-on runtime contract gate coverage                                                                                                                         |
| **Go**          | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with always-on runtime contract gate coverage                                                                                                                         |
| **Rust**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with always-on runtime contract gate coverage                                                                                                                         |
| **Ruby**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with deterministic wire tests and env-gated live-depth integration checks                                                                                             |
| **PHP**         | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with deterministic wire tests and env-gated live-depth integration checks                                                                                             |
| **Pascal**      | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with deterministic wire matrix coverage, env-gated live-depth checks, and enterprise diagnostics/telemetry/notification lifecycle APIs aligned to the .NET lane       |
| **Mojo**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Hybrid parity complete via native facade/bootstrap + opt-in SBWP wire bridge (`sb_wire_transport=python`), with direct/manager/listener runtime matrices and live-matrix CI gating; pure Mojo socket/TLS cutover remains roadmap work |

---

## Beta Drivers

| Driver                            | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State                                                                                                                                                                                                                                                                                                                                                                  |
| --------------------------------- | ---- | --- | ---- | ---- | ---- | --- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **C/C++ (libscratchbird_client)** | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE/ERR/RES with deterministic wire/C API coverage, enterprise diagnostics/telemetry/notification lifecycle surfaces, and begin-option transaction payload parity; transport remains intentionally IP-only (`inet_listener`/`managed`) with driver-side IPC/embedded delegated to ScratchBird server/engine layers |
| **R (DBI)**                       | 🟡   | 🟡  | ✅    | 🟡   | ✅    | ✅   | 🟡  | Execution/type/error parity is strongest; CONN/TXN/META/RES depth remains in progress                                                                                                                                                                                                                                                                                          |
| **Swift (Async/Await)**           | ✅    | 🟡  | 🟡   | 🟡   | 🟡   | 🟡  | 🟡  | CONN implemented with expanding deterministic parity tests; broader live integration remains pending                                                                                                                                                                                                                                                                           |
| **Dart**                          | ✅    | 🟡  | 🟡   | 🟡   | 🟡   | 🟡  | 🟡  | CONN implemented; TYPE/ERR parity significantly expanded (typed exceptions + SQLSTATE parsing/mapping), with direct + manager-proxy integration scaffolding now in place; broader live runtime depth remains pending                                                                                                                                                           |

---

## ## In Development

| Driver                    | Notes                                                                                                                                            |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Elixir (Ecto Adapter)** | Functional adapter, SCRAM + type layer present, but no full baseline mapping artifact yet. Considered in-development and not baseline-certified. |

---

## Ecosystem Adapter Status (Alpha Track)

| Adapter                | Current State                                                                                                                                                                     |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Prisma adapter**     | Deterministic adapter and contract suite implemented; runtime remains blocked by Prisma provider registration (`provider="scratchbird"` unsupported by stock Prisma CLI).         |
| **SQLAlchemy dialect** | Deterministic dialect and ORM/reflection contract suite implemented; live runtime matrix is blocked in this shell by endpoint TLS posture mismatch.                               |
| **Hibernate dialect**  | Deterministic dialect and contract suite implemented; runtime JDBC probe now passes with local JDBC jar auto-detected, while full JPA lifecycle/migration matrix remains pending. |
| **TypeORM adapter**    | Deterministic adapter and contract suite implemented; runtime remains blocked because stock TypeORM does not recognize `type="scratchbird"` (driver registry gap).                |

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages. These drivers target the ScratchBird native protocol (SBWP v1.1) and provide idiomatic APIs for each supported language.

Emulated protocols (PostgreSQL/MySQL/Firebird) are handled by their own native client drivers against ScratchBird's emulation listeners.

---

## Target Features (SBWP v1.1 Baseline)

All baseline drivers aim to implement:

- **Native Wire Protocol (SBWP v1.1)** – ScratchBird native protocol (port 3092)
- **TLS 1.3 Support** – Driver lanes expose configurable TLS posture; production defaults use TLS and lane-specific parity paths may allow explicit disable
- **Server-side Prepare/Bind** – PARSE/BIND/EXECUTE for parameters
- **Transactions** – Always-in-transaction semantics with autocommit mapping
- **Type Mapping** – Full wire type coverage (including composite/geometry/range)
- **Binary transfer and compression policy follow lane parity contracts (for example JDBC-compatible lanes accept `binary_transfer=false` and `compression=zstd`; unknown compression values are rejected)**

---

## Current Enterprise Readiness Tracking

Authoritative gap tracking lives in:

- `docs/planning/DRIVER_ENTERPRISE_READINESS_STRICT_IMPLEMENTATION_MATRIX_*.md`
- `docs/planning/DRIVER_ENTERPRISE_READINESS_REMAINING_GAPS_STRICT_*.md`
- `docs/planning/DRIVER_ENTERPRISE_READINESS_TICKETS_*.md`

This README provides a high-level executive summary. The planning documents remain the ticket-level source of truth.

---

## CLI Tools

| Tool                     | Purpose                              | Status                                                                                                                                                                              |
| ------------------------ | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **sb_isql**              | Native ScratchBird interactive shell | CONN ✅ / TXN 🟡 / EXEC ✅ / META 🟡 / TYPE 🟡 / ERR ✅ / RES 🟡                                                                                                                       |
| **sb_admin**             | Server administration CLI            | Baseline implemented                                                                                                                                                                |
| **sb_backup**            | Backup/restore CLI                   | Baseline implemented                                                                                                                                                                |
| **sb_security**          | User/role management CLI             | Baseline implemented                                                                                                                                                                |
| **sb_verify**            | Database verification CLI            | Baseline implemented                                                                                                                                                                |
| **sbdriver-conformance** | SBWP conformance adapter             | CONN ✅ / TXN 🟡 / EXEC ✅ / META 🟡 / TYPE 🟡 / ERR ✅ / RES 🟡 (`txn_exec`/`res_loop_exec` parity and typed manifest assertions implemented; live DSN-backed matrix remains partial) |

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
- **User Documentation:** `docs/user-documentation/`
- **Connection Modes and Auth:** `docs/user-documentation/connectivity/connection-modes-and-auth.md`
- **Specifications:** `docs/specifications/`
- **Development Guides:** `docs/development/`

For current installation, connection, and public API guidance, prefer the
getting-started guides, API references, and lane READMEs. Planning and
specification artifacts remain useful implementation references, but user-facing
guides are the intended entry point for the current driver behavior.

---

## Contributing

We welcome contributions. Please review `CONTRIBUTING.md` before submitting pull requests.

---

## License

Licensed under the Initial Developer's Public License (IDPL). See `LICENSE` for details.

---

**Last Updated:** 2026-03-06
