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

# Driver Capability Matrix (Audit Snapshot: 2026-03-03)

## Alpha Drivers

| Driver | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State |
|--------|------|-----|------|------|------|-----|-----|--------------|
| **Java / JDBC** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Most complete lane |
| **ODBC 3.8** | ✅ | ✅ | ✅ | 🟡 | ✅ | ✅ | ✅ | Near-complete baseline, metadata family parity remains |
| **.NET** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | Core usable, parity gaps remain in TXN/EXEC/META/TYPE |
| **Node.js** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Strong core, extended features partial |
| **Python** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Baseline working, not fully certified |
| **Go** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Infrastructure solid, parity incomplete |
| **Rust** | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ✅ | Strong type/error/resource layer, CONN/TXN/EXEC/META still partial |
| **Ruby** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Metadata execution APIs added, integration depth still shallow |
| **PHP** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | Resource lifecycle strongest surface |
| **Pascal** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | 🟡 | TLS/protocol solid, metadata execution added, integration limited |
| **Mojo** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Python-bridge adapter, partial baseline |

---

## Beta Drivers

| Driver | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State |
|--------|------|-----|------|------|------|-----|-----|--------------|
| **C/C++ (libscratchbird_client)** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Strong C API base, transport gaps |
| **R (DBI)** | 🟡 | 🟡 | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | Execution parity strongest surface, DBI metadata methods now present |
| **Swift (Async/Await)** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Connect complete, integration pending |
| **Dart** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Client metadata/schema-tree APIs added, live coverage pending |

---

## In Development

| Driver | Notes |
|--------|------|
| **Elixir (Ecto Adapter)** | Functional adapter, SCRAM + type layer present, but no full baseline mapping artifact yet. Considered in-development and not baseline-certified. |

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
| **sb_isql** | Native ScratchBird interactive shell | CONN ✅ / EXEC ✅ / TXN 🟡 |
| **sb_admin** | Server administration CLI | Baseline implemented |
| **sb_backup** | Backup/restore CLI | Baseline implemented |
| **sb_security** | User/role management CLI | Baseline implemented |
| **sb_verify** | Database verification CLI | Baseline implemented |
| **sbdriver-conformance** | SBWP conformance adapter | Baseline implemented |

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

**Last Updated:** 2026-03-03
