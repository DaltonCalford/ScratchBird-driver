# Rust Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/rust/src/errors.rs`. Issue: DONE (2026-03-04)


## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Use async-first APIs compatible with Tokio and futures. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Provide pool configuration for max connections, timeouts, and idle cleanup. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Support typed row mapping akin to `query_as` conventions. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify pool reconnects after transient network failures. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Ensure error types include SQLSTATE and implement `std::error::Error`. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/rust/tests/`. Issue: DONE (2026-02-04) (Sources: ``)
## P3 (Future)
