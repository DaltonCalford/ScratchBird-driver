# ScratchBird Prisma Adapter (Deterministic Scaffold)

This package provides deterministic building blocks for ECOSYS-401:

- ScratchBird datasource URL guardrails for Prisma-style configs
- ScratchBird-to-Prisma scalar/native type mapping helpers
- Metadata-to-`schema.prisma` model generation utility for introspection-style flows
- Deterministic reflection round-trip contract helper
- Deterministic migration plan builder for Prisma migration layout

## Run tests

```bash
cd tracks/alpha/integrations/scratchbird-prisma-adapter
node --test
```

## Scope notes

- This is not yet a full Prisma provider runtime.
- It provides adapter-level contract logic and deterministic tests to de-risk
  datasource validation, scalar mapping, schema generation, and migration/reflection workflows.

## Example workflow

```bash
cd tracks/alpha/integrations/scratchbird-prisma-adapter
node examples/migration-reflection-workflow.js
```
