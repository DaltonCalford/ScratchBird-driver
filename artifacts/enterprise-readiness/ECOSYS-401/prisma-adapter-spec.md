# ECOSYS-401 Prisma Adapter Spec

## Goal
Provide a first-party Prisma adapter path that supports:
- Introspection of ScratchBird catalogs
- CRUD and transaction execution
- Reflection and migration tooling compatibility

## Requirements
- Support both direct and managed/listener style connection strings.
- Mapping for core scalar + JSON-like types.
- Support for relation metadata sufficient for Prisma schema inference.

## Minimal Validation Plan
1. Run Prisma schema generation against a scratch database.
2. Run CRUD roundtrip for insert/select/update/delete.
3. Exercise nested include/transaction semantics.
4. Validate schema push/pull/reflect cycle for deterministic output.

## Acceptance
- The adapter integration commandset is available and scriptable.
- Failure modes are deterministic for unsupported data types.
