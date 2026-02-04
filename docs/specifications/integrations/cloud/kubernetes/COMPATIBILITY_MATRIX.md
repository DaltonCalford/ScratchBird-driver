# Kubernetes Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Kubernetes deployments require ConfigMaps and Secrets for configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| StatefulSets with persistent volumes are required for durable storage. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Readiness and liveness probes must be supported. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate rolling upgrade with zero data loss. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm liveness probes detect hung connections. | Yes | Deferred | Test criteria from SPECIFICATION.md |
