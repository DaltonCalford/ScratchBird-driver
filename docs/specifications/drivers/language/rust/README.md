# Rust Driver

Status: Current
Priority: P0
Category: language

## Authority

- Implementation spec: `docs/specifications/drivers/language/rust/SPECIFICATION.md`
- API reference: `docs/api-reference/rust.md`
- Getting started: `docs/getting-started/rust.md`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/rust.md`

## Current Truth

- Competitive benchmark: `tokio-postgres`
- Current state: `baseline_complete`
- Track root: `tracks/p3/drivers/rust`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is live benchmark and release-proof collection
