# CLI Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

### Integration Appendix Tasks

- [x] Constraint: Docker images must expose standard ports and support env-based configuration. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Non-root container execution should be supported. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Volume mounts are required for persistent data. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate container starts with read-only root filesystem. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm upgrade path via image tag changes. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Validate `sb_isql` against SBWP v1.1 conformance harness in `tracks/alpha/drivers/cli/sb_isql.cpp`. Issue: DEFERRED (2026-02-04) (Sources: ``)
- [x] Validate `sbdriver_conformance` output against `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`. Issue: DEFERRED (2026-02-04) (Sources: ``)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Prometheus scrapes HTTP endpoints (`/metrics`) and expects stable label sets. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Database integration typically relies on exporters; the driver should not require interactive auth. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Metrics must be safe for high-frequency scraping. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate scrape performance at 15s intervals with minimal allocation. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Ensure metrics include connection pool, query latency, and error counts. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Azure deployments commonly use VNet integration and NSGs for port access. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: TLS certificates must be compatible with Azure Load Balancers and App Gateways. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Managed service deployments should support Azure backup/restore patterns. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate connectivity through Azure App Gateway. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm backup/restore procedures. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Terraform modules should expose variables for ports, storage, and credentials. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: State changes must be idempotent across applies. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Outputs should include connection strings for downstream tooling. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate plan/apply on clean and existing environments. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm destroy cleans up all resources. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: AWS deployments typically use VPC networking, security groups, and IAM roles. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Managed deployments should align with RDS-style parameter groups and backups. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: TLS certificates must be compatible with AWS load balancers. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate connectivity through cloud load balancers. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`, `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Kubernetes deployments require ConfigMaps and Secrets for configuration. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: StatefulSets with persistent volumes are required for durable storage. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Readiness and liveness probes must be supported. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate rolling upgrade with zero data loss. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm liveness probes detect hung connections. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: GCP deployments use service accounts and firewall rules for connectivity. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Cloud SQL-style deployments require TLS and IAM-aware connection policies. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Health checks must be compatible with Google Load Balancers. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P3 (Future)
