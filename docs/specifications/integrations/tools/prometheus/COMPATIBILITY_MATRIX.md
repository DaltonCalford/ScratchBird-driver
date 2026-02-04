# Prometheus Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Prometheus scrapes HTTP endpoints (`/metrics`) and expects stable label sets. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Database integration typically relies on exporters; the driver should not require interactive auth. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Metrics must be safe for high-frequency scraping. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate scrape performance at 15s intervals with minimal allocation. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Ensure metrics include connection pool, query latency, and error counts. | Yes | Deferred | Test criteria from SPECIFICATION.md |
