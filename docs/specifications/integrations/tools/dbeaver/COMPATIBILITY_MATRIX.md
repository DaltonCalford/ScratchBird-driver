# DBeaver Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| DBeaver relies on JDBC drivers and expects a JDBC URL for connections. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Driver registration and classpath loading must work with custom driver jars. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Metadata queries must be efficient to avoid UI timeouts. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate schema browser loads tables, columns, and indexes. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm DBeaver can generate and execute `SELECT` previews. | Yes | Deferred | Test criteria from SPECIFICATION.md |
