# Go Driver

Status: Current
Priority: P0
Category: language

## Authority

- Implementation spec: `docs/specifications/drivers/language/golang/SPECIFICATION.md`
- API reference: `docs/api-reference/go.md`
- Getting started: `docs/getting-started/go.md`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/go.md`

## Current Truth

- Competitive benchmark: `pgx`
- Current state: `baseline_complete`
- Track root: `tracks/p3/drivers/go`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is server-backed benchmark, compatibility, and release proof collection
