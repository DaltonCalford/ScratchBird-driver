# TypeORM Adapter

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_contract_only`
- Best-in-class benchmark: `TypeORM PostgreSQL driver`
- Authoritative lane spec: `docs/application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/typeorm.md`
- Remaining gap summary: The adapter is contract-first today; stock driver registry gaps and live runtime validation remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/TYPEORM_COMPATIBILITY_SPECIFICATION.md`
- API/reference: `../api-reference/typeorm.md`

## Build / Install

- `cd tracks/alpha/integrations/scratchbird-typeorm-adapter`
- `npm install`

## Later Verification Inputs

- `DATABASE_URL`

## Later Verification Commands

- `npm test`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
