# .NET Driver

Status: Current
Priority: P0
Category: language

## Authority

- Implementation spec: `docs/specifications/drivers/language/dotnet-csharp/SPECIFICATION.md`
- API reference: `docs/api-reference/dotnet.md`
- Getting started: `docs/getting-started/dotnet.md`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/dotnet.md`

## Current Truth

- Competitive benchmark: `Npgsql`
- Current state: `baseline_complete`
- Track root: `tracks/p3/drivers/dotnet`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is competitive proof, packaging polish, and later live evidence collection
