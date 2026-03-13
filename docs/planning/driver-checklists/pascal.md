# Pascal/Delphi Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/p3/drivers/pascal/src/ScratchBird.Errors.pas`. Issue: DONE (2026-03-04)

### Integration Appendix Tasks

- [x] Constraint: SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: ConnectorType selects backend driver at runtime. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate transaction behavior via TSQLTransaction. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm schema retrieval APIs (SQLDB) return expected shapes. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P2 (Follow-ups)
- [x] Add conformance tests for full type matrix in `tracks/p3/drivers/pascal/tests/`. Issue: DONE (2026-02-04)

## P3 (Future)
