# AWS Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| AWS deployments typically use VPC networking, security groups, and IAM roles. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Managed deployments should align with RDS-style parameter groups and backups. | Yes | Deferred | Constraint from SPECIFICATION.md |
| TLS certificates must be compatible with AWS load balancers. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate connectivity through AWS load balancers. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm backups and restore procedures. | Yes | Deferred | Test criteria from SPECIFICATION.md |
