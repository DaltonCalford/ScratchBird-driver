# Driver Comparison

**Status:** SBWP v1.1 baseline (tracks: alpha/beta/p3)
**Last Updated:** 2026-02-04

---

## Overview

All drivers in this repository speak the ScratchBird native wire protocol (SBWP v1.1)
against the native listener on port 3092. This page compares the native drivers only
and links to the language-specific guides.

## Driver Matrix

| Language | Driver | Status | Notes |
|----------|--------|--------|-------|
| C/C++ | libscratchbird_client | Beta | C API, CMake build |
| ODBC | ScratchBird ODBC 3.8 | Alpha | BI/legacy tools |
| Go | scratchbird-go | Alpha | database/sql driver |
| Python | scratchbird | Alpha | DB-API 2.0 |
| Node.js | scratchbird | Alpha | TypeScript types |
| Ruby | scratchbird | Alpha | Native gem |
| Rust | scratchbird | Alpha | Async runtime |
| PHP | ScratchBird PDO | Alpha | Pure-PHP driver |
| R | scratchbird | Beta | DBI driver |
| Pascal/Delphi | ScratchBird.Client | Alpha | Delphi/FreePascal |
| .NET | ScratchBird.Data | Alpha | ADO.NET provider |
| Java | ScratchBird JDBC | Alpha | JDBC 4.x |
| Elixir | ScratchBird.Ecto | P3 | Ecto adapter |
| Swift | ScratchBird | Beta | Native SBWP client |
| Dart | scratchbird | Beta | Flutter-ready |
| Mojo | scratchbird | Alpha | Native SBWP client |

## Capability Baseline

- SBWP v1.1, binary-only parameters
- Server-side prepare/bind
- TLS 1.3 required
- Wrapper types for JSONB/RANGE/GEOMETRY
- Streaming/paging support where applicable

## Pick the Right Driver

- Use the native driver for your language to get full SBWP feature coverage.
- Use ODBC for BI tools or legacy applications that only speak ODBC.

## Related

- [Drivers index](../Drivers.md)
- [Conformance testing](../Conformance-Testing.md)
- [Protocol and specs](../Protocol-and-Specs.md)
