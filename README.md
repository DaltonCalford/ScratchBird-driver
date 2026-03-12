# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

---

## Project Status

ScratchBird-driver is in **Initial Early Beta (`1.0`)**.

All released drivers implement the **ScratchBird Wire Protocol (SBWP v1.1)**
baseline handshake and core execution path, but closure status still varies by
lane.

Current PH5 closure progress:

- `NCW-050..054` are complete.
- `NCW-054A` is now complete, and `NCW-054B..054D` remain as the immediate
  full-surface uplift block for previously residual driver work.
- Required closure slices are complete for JDBC, ODBC, Go, Node, Python, PHP,
  Rust, Ruby, Pascal, .NET, and C/C++.
- Remaining driver implementation work is concentrated in `NCW-054B..054D`
  (residual/full-surface uplift for already-closed lanes), `NCW-055`
  (R/Dart/Swift), `NCW-056` (Elixir/Mojo), and `NCW-057` (cross-driver
  promotion/conformance regeneration).

This README reflects the current implementation-closure state, not the final
cross-driver promotion decision. PH5 no longer treats convenience, downstream
consumer, or other previously residual driver surfaces as optional.

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

- ✅ Required PH5 closure slice complete on the currently supported surface
- 🟡 Partial (usable but still has active closure work)
- 🔴 Gap (explicitly incomplete or scaffold-only)

---

# Driver Capability Matrix (Work Snapshot: 2026-03-12)

This matrix reflects the current PH5 closure state after `NCW-054A`. A `✅`
entry means the required closure slice is complete for the lane's actively
supported surface. `NCW-054A` has already absorbed the primary-alpha residuals;
`NCW-054B..054D` now carry the remaining full-surface uplift work before PH5
can claim final closure.

## Alpha Drivers

| Driver          | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State                                                                                                                                                                                        |
| --------------- | ---- | --- | ---- | ---- | ---- | --- | --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Java / JDBC** | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Baseline reference lane; `NCW-054` closed the remaining schema-resolution, metadata anchoring, always-in-transaction, and pool-reset ambiguity.                                                  |
| **ODBC 3.8**    | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green on the packaged runtime/catalog/type surface; broader promotion regeneration remains in `NCW-057`.                                                              |
| **.NET**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green; the previously residual `DataReader.NextResult()` and related advanced result-workflow parity now move into the PH5 uplift block.                            |
| **Node.js**     | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green, and `NCW-054A` also closed the former residuals for routine metadata, metadata convenience wrappers, wire-level autocommit handling, and `users.public` schema fallback alignment.                            |
| **Python**      | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green, and `NCW-054A` also closed executable procedure/function/routine metadata plus `users.public` session-schema fallback alignment on the live wrapper surface.                                                 |
| **Go**          | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green across the primary live select/prepare/type/cancel and metadata helper surface.                                                                                  |
| **Rust**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green; the previously residual multi-result and callable-path parity now move into the PH5 uplift block.                                                              |
| **Ruby**        | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green with live `sslmode=disable`, prepare/bind normalization, metadata restriction shaping, and resource cleanup.                                                    |
| **PHP**         | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green, and `NCW-054A` also closed schema-aware routine metadata, first-class metadata convenience wrappers, and session-schema convenience handling aligned to `users.public`.                                       |
| **Pascal**      | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green with direct plain-socket `sslmode=disable`, result-stream auto-drain, and always-in-a-transaction session semantics.                                           |
| **Mojo**        | 🟡   | 🔴  | 🔴   | 🔴   | 🔴   | 🔴  | 🔴  | Still in specialty-lane implementation (`NCW-056`); current surface remains a Python-bridge-backed scaffold rather than a closed native SBWP client lane.                                          |

---

## Beta Drivers

| Driver                            | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State                                                                                                                                                                                                                                                                                               |
| --------------------------------- | ---- | --- | ---- | ---- | ---- | --- | --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **C/C++ (libscratchbird_client)** | ✅    | ✅   | ✅    | ✅    | ✅    | ✅   | ✅   | Required PH5 closure slice is green across public API, metadata helpers, type fidelity, resource lifecycle, and always-in-transaction wrapper state; transport remains intentionally listener/IP-bound.                                                                                                  |
| **R (DBI)**                       | 🟡   | 🟡  | ✅    | 🟡   | 🟡   | 🟡  | 🟡  | Still in active PH5 closure work (`NCW-055`); execution is strongest, but live connection, transaction, metadata, type, error, and resource depth remain open.                                                                                                                                             |
| **Swift (Async/Await)**           | ✅    | 🟡  | 🟡   | 🟡   | 🟡   | 🟡  | 🟡  | Still in active PH5 closure work (`NCW-055`); base connection path exists, but broader live TXN/EXEC/META/TYPE/ERR/RES coverage remains open.                                                                                                                                                           |
| **Dart**                          | ✅    | 🟡  | 🟡   | 🟡   | 🟡   | 🟡  | 🟡  | Still in active PH5 closure work (`NCW-055`); connection path is present, but live transaction, metadata, type, error, and resilience closure is still pending.                                                                                                                                          |

---

## Specialty / In Development

| Driver                    | Notes                                                                                                                                            |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Elixir (Ecto Adapter)** | Functional adapter, SCRAM + type layer present, but the specialty lane is still open in `NCW-056`; it is not baseline-certified yet.            |

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

**Last Updated:** 2026-03-12
