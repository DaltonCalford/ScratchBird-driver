# R Driver

Status: Current
Priority: P2
Category: language

## Authority

- Implementation spec: `docs/specifications/drivers/language/r/SPECIFICATION.md`
- API reference: `docs/api-reference/r.md`
- Getting started: `docs/getting-started/r.md`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/r.md`

## Current Truth

- Competitive benchmark: `RPostgres`
- Current state: `partial`
- Track root: `tracks/p3/drivers/r`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

- CONN: connection/auth integration coverage remains environment-gated
- META: richer privilege/key/type and DDL-editor metadata parity remains incomplete
