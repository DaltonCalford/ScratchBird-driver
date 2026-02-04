# Pascal/Delphi Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Constraint: ConnectorType selects backend driver at runtime. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Test: Validate transaction behavior via TSQLTransaction. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
- [ ] Test: Confirm schema retrieval APIs (SQLDB) return expected shapes. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)
## P2 (Follow-ups)
- [ ] Add conformance tests for full type matrix in `pascal/tests/`. Issue: TBD

## P3 (Future)