# Pascal/Delphi Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `pascal/src/ScratchBird.Errors.pas`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow. (Source: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Constraint: ConnectorType selects backend driver at runtime. (Source: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Test: Validate transaction behavior via TSQLTransaction. (Source: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Test: Confirm schema retrieval APIs (SQLDB) return expected shapes. (Source: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `pascal/tests/`. Issue: TBD
