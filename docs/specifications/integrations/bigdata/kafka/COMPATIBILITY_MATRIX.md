# Apache Kafka Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Kafka Connect JDBC sink uses connector configs like `connection.url` and `table.name.format`. | Yes | Deferred | Constraint from SPECIFICATION.md |
| The driver must support auto-commit behavior expected by the sink. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Batch inserts and retries must be stable under load. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate sink retries on transient errors. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm schema evolution for added columns. | Yes | Deferred | Test criteria from SPECIFICATION.md |
