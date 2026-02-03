# Driver Comparison

**Status:** SBWP v1.1 baseline (native-only drivers)
**Last Updated:** 2026-02-02

---

## Overview

All drivers in this repository speak the ScratchBird native wire protocol (SBWP v1.1)
against the native listener on port 3092. This page compares the native drivers only
and links to the language-specific guides.

## Driver Matrix

| Language | Driver | Status | Notes |
|----------|--------|--------|-------|
| C/C++ | libscratchbird_client | Implemented | C API, CMake build |
| ODBC | ScratchBird ODBC 3.8 | Implemented | BI/legacy tools |
| Go | scratchbird-go | Implemented | database/sql driver |
| Python | scratchbird | Implemented | DB-API 2.0 |
| Node.js | scratchbird | Implemented | TypeScript types |
| Ruby | scratchbird | Implemented | Native gem |
| Rust | scratchbird | Implemented | Async runtime |
| PHP | ScratchBird PDO | Implemented | Pure-PHP driver |
| R | scratchbird | Implemented | DBI driver |
| Pascal/Delphi | ScratchBird.Client | Implemented | Delphi/FreePascal |
| .NET | ScratchBird.Data | Implemented | ADO.NET provider |
| Java | ScratchBird JDBC | Implemented | JDBC 4.x |
| Elixir | ScratchBird.Ecto | Preview | Ecto adapter |
| Swift | ScratchBird | Preview | TCP transport, TLS pending |
| Dart | scratchbird | Preview | Flutter-ready |
| Mojo | scratchbird (bridge) | Preview | Python transport bridge |

## Capability Baseline

- SBWP v1.1, binary-only parameters
- Server-side prepare/bind
- TLS 1.3 required (Swift is pending TLS wiring)
- Wrapper types for JSONB/RANGE/GEOMETRY
- Streaming/paging support where applicable

## Pick the Right Driver

- Use the native driver for your language to get full SBWP feature coverage.
- Use ODBC for BI tools or legacy applications that only speak ODBC.

## Related

- [Drivers index](../Drivers.md)
- [Conformance testing](../Conformance-Testing.md)
- [Protocol and specs](../Protocol-and-Specs.md)

