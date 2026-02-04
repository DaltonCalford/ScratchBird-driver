# R Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [ ] Add SQLSTATE class-prefix mapping (currently only prefixes message) in `tracks/beta/drivers/r/R/client.R`. Issue: TBD


## P2 (Follow-ups)
- [ ] Add conformance tests for full type matrix in `tracks/beta/drivers/r/tests/`. Issue: TBD

## P3 (Future)

### Integration Appendix Tasks

- [ ] Constraint: Conform to R DBI generics and return data frames with stable column classes. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Constraint: Support `dbListTables` and `dbColumnInfo` for metadata introspection. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Constraint: Treat `NA` and `NULL` per DBI expectations. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Test: Validate `dbGetQuery` returns consistent `data.frame` column types. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Test: Ensure `dbBind` supports positional and named parameters. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)