# Driver Comparison

**Status:** Initial early beta (`0.1.0`) for completed drivers; in-development drivers continue post-`0.1.0`
**Last Updated:** 2026-02-18

---

## Overview

Core drivers in this repository speak the ScratchBird native wire protocol (SBWP v1.1)
against the native listener on port 3092. This page compares the native drivers only
and links to the language-specific guides.

## Driver Matrix

| Language | Driver | Status | Notes |
|----------|--------|--------|-------|
| C/C++ | libscratchbird_client | Initial Early Beta (`0.1.0`) | C API, CMake build |
| ODBC | ScratchBird ODBC 3.8 | Initial Early Beta (`0.1.0`) | BI/legacy tools |
| Go | scratchbird-go | Initial Early Beta (`0.1.0`) | database/sql driver |
| Python | scratchbird | Initial Early Beta (`0.1.0`) | DB-API 2.0 |
| Node.js | scratchbird | Initial Early Beta (`0.1.0`) | TypeScript types |
| Ruby | scratchbird | Initial Early Beta (`0.1.0`) | Native gem |
| Rust | scratchbird | Initial Early Beta (`0.1.0`) | Async runtime |
| PHP | ScratchBird PDO | Initial Early Beta (`0.1.0`) | Pure-PHP driver |
| R | scratchbird | Initial Early Beta (`0.1.0`) | DBI driver |
| Pascal/Delphi | ScratchBird.Client | Initial Early Beta (`0.1.0`) | Delphi/FreePascal |
| .NET | ScratchBird.Data | Initial Early Beta (`0.1.0`) | ADO.NET provider |
| Java | ScratchBird JDBC | Initial Early Beta (`0.1.0`) | JDBC 4.x |
| Elixir | ScratchBird.Ecto | In development | Ecto adapter |
| Swift | ScratchBird | In development | Partial; metadata/conformance incomplete |
| Dart | scratchbird | In development | Partial; metadata/conformance incomplete |
| Mojo | scratchbird | In development | Python bridge; native client pending |

## Capability Baseline (Core Drivers)

- SBWP v1.1, binary-only parameters
- Server-side prepare/bind
- TLS 1.3 required
- Wrapper types for JSONB/RANGE/GEOMETRY
- Streaming/paging support where applicable

## Pick the Right Driver

- Use the native driver for your language to get full SBWP feature coverage (core drivers).
- Use ODBC for BI tools or legacy applications that only speak ODBC.

## Related

- [Drivers index](../Drivers.md)
- [Conformance testing](../Conformance-Testing.md)
- [Protocol and specs](../Protocol-and-Specs.md)
