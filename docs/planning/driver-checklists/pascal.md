# Pascal/Delphi Driver Checklist

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Constraint: ConnectorType selects backend driver at runtime. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Test: Validate transaction behavior via TSQLTransaction. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Test: Confirm schema retrieval APIs (SQLDB) return expected shapes. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `pascal/src/ScratchBird.Errors.pas`. Issue: TBD


## P2 (Follow-ups)
- [ ] Add conformance tests for full type matrix in `pascal/tests/`. Issue: TBD

## P3 (Future)
