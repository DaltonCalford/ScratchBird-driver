# Hadoop Hive Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Hive JDBC storage handlers require JDBC URL and driver class configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Hive expects column types to map to SQL types for external tables. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Queries should support predicate pushdown where possible. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Hive external table read/write against ScratchBird. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm predicate pushdown reduces row counts. | Yes | Deferred | Test criteria from SPECIFICATION.md |
