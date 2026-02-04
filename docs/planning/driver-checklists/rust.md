# Rust Driver Checklist

## P1 (Core)
- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `rust/src/errors.rs`. Issue: TBD


## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Use async-first APIs compatible with Tokio and futures. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Constraint: Provide pool configuration for max connections, timeouts, and idle cleanup. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Constraint: Support typed row mapping akin to `query_as` conventions. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Test: Verify pool reconnects after transient network failures. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Test: Ensure error types include SQLSTATE and implement `std::error::Error`. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Add conformance tests for full type matrix in `rust/tests/`. Issue: TBD

## P3 (Future)
