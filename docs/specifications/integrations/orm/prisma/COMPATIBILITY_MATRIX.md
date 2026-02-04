# Prisma Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Prisma expects a `datasource` and `generator` in `schema.prisma` with a connection URL. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Support introspection flows (similar to `prisma db pull`) and migrations (similar to `prisma migrate`). | Yes | Deferred | Constraint from SPECIFICATION.md |
| Ensure scalar types map cleanly to Prisma field types and `@db` native types. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate introspection against a schema with enums, arrays, and JSON. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Ensure Prisma Client queries return correct nullability and enum mappings. | Yes | Deferred | Test criteria from SPECIFICATION.md |
