# Rust Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `rust/src/errors.rs`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: Use async-first APIs compatible with Tokio and futures. (Source: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Constraint: Provide pool configuration for max connections, timeouts, and idle cleanup. (Source: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Constraint: Support typed row mapping akin to `query_as` conventions. (Source: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Test: Verify pool reconnects after transient network failures. (Source: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)
- [ ] Test: Ensure error types include SQLSTATE and implement `std::error::Error`. (Source: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `rust/tests/`. Issue: TBD
