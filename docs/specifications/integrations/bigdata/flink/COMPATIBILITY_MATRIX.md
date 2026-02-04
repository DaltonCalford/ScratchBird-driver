# Apache Flink Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Flink JDBC connector requires JDBC URL, driver class, and table schema mapping. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Upserts and batch modes should be supported for sinks. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Exactly-once semantics depend on transaction and checkpoint support. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Flink sink upserts under checkpointing. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm JDBC source reads with projection and filters. | Yes | Deferred | Test criteria from SPECIFICATION.md |
