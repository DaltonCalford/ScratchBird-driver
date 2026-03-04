# Prisma Adapter Artifact

Authoritative implementation now lives at:

- `tracks/alpha/integrations/scratchbird-prisma-adapter`

This artifact folder is retained for enterprise-readiness evidence and verification logs.

Implemented deterministic scope:

- secure ScratchBird datasource URL validation for Prisma-style configs
- ScratchBird -> Prisma scalar/native mapping helpers
- metadata-to-`schema.prisma` generation utility
- deterministic migration/reflection workflow helpers
- deterministic workflow example (`examples/migration-reflection-workflow.js`)
- deterministic Node contract suite (`node --test`)

Remaining live scope:

- runtime Prisma CLI (`db pull`, `migrate`, client CRUD/transactions) against live DSN.
- runtime probe script:
  - `artifacts/enterprise-readiness/ECOSYS-401/verification_prisma_runtime_probe.sh`
- runtime provider blocker evidence:
  - `artifacts/enterprise-readiness/ECOSYS-401/runtime_provider_blocker_2026-03-04.md`
