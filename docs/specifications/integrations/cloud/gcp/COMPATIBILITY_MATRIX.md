# GCP Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| GCP deployments use service accounts and firewall rules for connectivity. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Cloud SQL-style deployments require TLS and IAM-aware connection policies. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Health checks must be compatible with Google Load Balancers. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate connectivity through GCP load balancers. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm automated backups and point-in-time restore. | Yes | Deferred | Test criteria from SPECIFICATION.md |
