# C/C++ Driver

Status: Current
Priority: P0
Category: language

## Authority

- Implementation spec: `docs/specifications/drivers/language/cpp/SPECIFICATION.md`
- API reference: `docs/api-reference/cpp.md`
- Getting started: `docs/getting-started/cpp.md`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/cpp.md`

## Current Truth

- Competitive benchmark: `libpqxx`
- Current state: `baseline_complete`
- Track root: `tracks/p3/drivers/cpp`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is server-backed proof collection and competitive release evidence
