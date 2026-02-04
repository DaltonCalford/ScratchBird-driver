# Terraform Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Terraform modules should expose variables for ports, storage, and credentials. | Yes | Deferred | Constraint from SPECIFICATION.md |
| State changes must be idempotent across applies. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Outputs should include connection strings for downstream tooling. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate plan/apply on clean and existing environments. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm destroy cleans up all resources. | Yes | Deferred | Test criteria from SPECIFICATION.md |
