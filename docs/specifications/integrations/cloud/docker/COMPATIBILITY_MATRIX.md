# Docker Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Docker images must expose standard ports and support env-based configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Non-root container execution should be supported. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Volume mounts are required for persistent data. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate container starts with read-only root filesystem. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm upgrade path via image tag changes. | Yes | Deferred | Test criteria from SPECIFICATION.md |
