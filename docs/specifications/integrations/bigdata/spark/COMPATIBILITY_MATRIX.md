# Apache Spark Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Spark JDBC data sources require a JDBC URL, table or query, and driver class. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Partitioning options should be supported for parallel read. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Large writes should use batch inserts and prepared statements. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Spark parallel read with partition column + bounds. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm DataFrame writes via JDBC with batch size tuning. | Yes | Deferred | Test criteria from SPECIFICATION.md |
