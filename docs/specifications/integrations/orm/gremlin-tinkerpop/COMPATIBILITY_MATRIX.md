# Gremlin/TinkerPop Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Gremlin uses traversal steps (`g.V()`, `has`, `out`, `values`) and expects streaming results. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Parameterized bindings are common in Gremlin to avoid string interpolation. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Result types include vertices, edges, and property maps. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate traversal step ordering and pagination semantics. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Ensure vertex/edge property maps are decoded consistently. | Yes | Deferred | Test criteria from SPECIFICATION.md |
