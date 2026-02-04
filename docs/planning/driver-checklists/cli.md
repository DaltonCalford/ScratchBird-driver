# CLI Checklist

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: Docker images must expose standard ports and support env-based configuration. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)
- [ ] Constraint: Non-root container execution should be supported. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)
- [ ] Constraint: Volume mounts are required for persistent data. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)
- [ ] Test: Validate container starts with read-only root filesystem. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)
- [ ] Test: Confirm upgrade path via image tag changes. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)
- [ ] Validate `sb_isql` against SBWP v1.1 conformance harness in `cli/sb_isql.cpp`. Issue: TBD
- [ ] Validate `sbdriver_conformance` output against `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`. Issue: TBD


## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Prometheus scrapes HTTP endpoints (`/metrics`) and expects stable label sets. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)
- [ ] Constraint: Database integration typically relies on exporters; the driver should not require interactive auth. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)
- [ ] Constraint: Metrics must be safe for high-frequency scraping. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)
- [ ] Test: Validate scrape performance at 15s intervals with minimal allocation. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)
- [ ] Test: Ensure metrics include connection pool, query latency, and error counts. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)
- [ ] Constraint: Azure deployments commonly use VNet integration and NSGs for port access. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)
- [ ] Constraint: TLS certificates must be compatible with Azure Load Balancers and App Gateways. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)
- [ ] Constraint: Managed service deployments should support Azure backup/restore patterns. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)
- [ ] Test: Validate connectivity through Azure App Gateway. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)
- [ ] Test: Confirm backup/restore procedures. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)
- [ ] Constraint: Terraform modules should expose variables for ports, storage, and credentials. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)
- [ ] Constraint: State changes must be idempotent across applies. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)
- [ ] Constraint: Outputs should include connection strings for downstream tooling. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)
- [ ] Test: Validate plan/apply on clean and existing environments. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)
- [ ] Test: Confirm destroy cleans up all resources. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)
- [ ] Constraint: AWS deployments typically use VPC networking, security groups, and IAM roles. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)
- [ ] Constraint: Managed deployments should align with RDS-style parameter groups and backups. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)
- [ ] Constraint: TLS certificates must be compatible with AWS load balancers. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)
- [ ] Test: Validate connectivity through AWS load balancers. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)
- [ ] Test: Confirm backups and restore procedures. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)
- [ ] Constraint: Kubernetes deployments require ConfigMaps and Secrets for configuration. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)
- [ ] Constraint: StatefulSets with persistent volumes are required for durable storage. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)
- [ ] Constraint: Readiness and liveness probes must be supported. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)
- [ ] Test: Validate rolling upgrade with zero data loss. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)
- [ ] Test: Confirm liveness probes detect hung connections. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)
- [ ] Constraint: GCP deployments use service accounts and firewall rules for connectivity. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)
- [ ] Constraint: Cloud SQL-style deployments require TLS and IAM-aware connection policies. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)
- [ ] Constraint: Health checks must be compatible with Google Load Balancers. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)
- [ ] Test: Validate connectivity through GCP load balancers. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)
- [ ] Test: Confirm automated backups and point-in-time restore. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)
## P3 (Future)
