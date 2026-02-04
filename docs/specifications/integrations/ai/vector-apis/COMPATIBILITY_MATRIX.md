# Vector APIs Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Vector APIs expect fixed-dimension vector columns and similarity operators. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Index choices (HNSW/IVF) can affect performance and accuracy tradeoffs. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Distance functions must be deterministic and numeric-safe. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate vector insert/update and top-k similarity queries. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm index build time and recall thresholds. | Yes | Deferred | Test criteria from SPECIFICATION.md |
