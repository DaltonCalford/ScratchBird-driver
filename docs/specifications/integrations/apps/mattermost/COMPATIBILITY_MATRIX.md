# Mattermost Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Mattermost uses PostgreSQL for production deployments. | Yes | Deferred | Constraint from SPECIFICATION.md |
| DB connection config is in `config.json` with DSN-like fields. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Online migrations are common during upgrades. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Mattermost startup migrations complete. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm message, channel, and user CRUD flows. | Yes | Deferred | Test criteria from SPECIFICATION.md |
