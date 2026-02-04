# Hadoop Pig Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Pig DBStorage supports storing data to JDBC targets and requires driver jars. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Schema mapping must preserve column ordering and nullability. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Large batch writes should be chunked to avoid memory spikes. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate DBStorage write path with large datasets. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm NULL handling for optional fields. | Yes | Deferred | Test criteria from SPECIFICATION.md |
