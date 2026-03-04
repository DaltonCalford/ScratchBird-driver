# ScratchBird TypeORM Adapter (Deterministic Contract)

This package provides deterministic contract coverage for `ECOSYS-404`.

## Scope

- TypeORM datasource option guardrails for ScratchBird policy parity
- ScratchBird type -> TypeORM column mapping helper
- Metadata to TypeORM-style entity schema generation
- Nested relation CRUD/transaction contract planning helper

## Run tests

```bash
cd tracks/alpha/integrations/scratchbird-typeorm-adapter
node --test
```

## Runtime note

This package focuses on deterministic adapter contracts. Full live TypeORM runtime
execution against managed/listener endpoints remains environment-gated.

## Example

- `examples/sample-service.js`
