# ECOSYS-401 Prisma Adapter Spec

## Goal
Provide a first-party Prisma adapter path that supports:
- Introspection of ScratchBird catalogs
- CRUD and transaction execution
- Reflection and migration tooling compatibility

## Implemented Deterministic Components
- Connection URL guardrails for ScratchBird DSNs:
  - reject `sslmode=disable`
  - reject `binary_transfer=false` aliases
  - reject `compression=zstd`
- Scalar/native mapping helpers from ScratchBird type names to Prisma field shapes.
- Metadata-to-`schema.prisma` generator utility for introspection-style model scaffolding.
- Deterministic reflection round-trip helper that validates generated schema contracts.
- Deterministic migration plan helper that produces stable Prisma migration directory/file naming from schema fingerprinting.
- Deterministic Node contract tests (`node --test`) for the above behavior.

## Remaining Runtime Components
- Live Prisma CLI matrix (`db pull`, `migrate`, `generate`) against runtime DSN.
- Client runtime CRUD + transaction matrix against live server.
- Relation/constraint parity validation across nested includes and transactional flows.

## Current Runtime Blocker
- Prisma CLI rejects `provider = "scratchbird"` with `P1012` (`Datasource provider not known`).
- Blocker evidence: `artifacts/enterprise-readiness/ECOSYS-401/runtime_provider_blocker_2026-03-04.md`.

## Validation Plan
1. Run deterministic Node contract suite in-tree.
2. Run live Prisma schema generation against runtime DSN (env-gated).
3. Run live CRUD roundtrip for insert/select/update/delete.
4. Exercise nested include/transaction semantics.
5. Validate schema push/pull/reflect cycle for deterministic output.

## Acceptance
- Adapter contract logic is implemented and scriptable in-tree.
- Failure modes are deterministic for unsupported config/type paths.
- Live Prisma CLI/runtime matrix is captured once runtime endpoints are available.
