# PHP Driver

Status: Current
Priority: P0
Category: language

## Authority

- Implementation spec: `docs/specifications/drivers/language/php/SPECIFICATION.md`
- API reference: `docs/api-reference/php.md`
- Getting started: `docs/getting-started/php.md`
- Release evidence templates: `docs/development/release-evidence/README.md`
- Later server verification packet: `docs/development/server-verification/php.md`

## Current Truth

- Competitive benchmark: `PDO_PGSQL`
- Current state: `baseline_complete`
- Track root: `tracks/p3/drivers/php`

## Remaining Work Split

Completed without a server:

- benchmark-driven specification closure
- release-evidence contract wiring
- later verification packet definition

Still server-blocked:

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is server-backed performance and packaging proof collection
