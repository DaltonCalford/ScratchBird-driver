# Prisma Adapter

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `partial_contract_only`
- Best-in-class benchmark: `Prisma PostgreSQL connector`
- Authoritative lane spec: `docs/application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/prisma.md`
- Remaining gap summary: The adapter is contract-first today; stock Prisma provider registration and live integration validation remain open.
<!-- lane-status:end -->

## Authority

- Compatibility specification: `../application-reference/PRISMA_COMPATIBILITY_SPECIFICATION.md`
- API/reference: `../api-reference/prisma.md`

## Build / Install

- `cd tracks/alpha/integrations/scratchbird-prisma-adapter`
- `npm install`

## Later Verification Inputs

- `DATABASE_URL`

## Later Verification Commands

- `npm test`

## Notes

This adapter is documented to a server-independent completion state. Final
compatibility proof remains blocked on a working ScratchBird test server.
