# LangChain Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| LangChain SQL integrations expect SQLAlchemy-style connection URIs. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Query results are consumed by chains that expect consistent column naming. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Parameter binding must be compatible with SQLAlchemy engine conventions. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate schema introspection and sample query execution. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm long-running queries can be cancelled by the chain. | Yes | Deferred | Test criteria from SPECIFICATION.md |
