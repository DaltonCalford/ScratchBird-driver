# Haystack Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Haystack document stores expect consistent schema and efficient filter predicates. | Yes | Deferred | Constraint from SPECIFICATION.md |
| SQL-backed document stores require parameterized queries and transaction safety. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Embedding/vector fields must preserve dimensionality and order. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate insert/update/delete for documents with metadata filters. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm vector similarity queries return stable ordering. | Yes | Deferred | Test criteria from SPECIFICATION.md |
