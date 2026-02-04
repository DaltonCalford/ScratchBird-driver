# R Driver Checklist

## P1 (Core)

- [ ] Add SQLSTATE class-prefix mapping (currently only prefixes message) in `r/R/client.R`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: Conform to R DBI generics and return data frames with stable column classes. (Source: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Constraint: Support `dbListTables` and `dbColumnInfo` for metadata introspection. (Source: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Constraint: Treat `NA` and `NULL` per DBI expectations. (Source: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Test: Validate `dbGetQuery` returns consistent `data.frame` column types. (Source: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)
- [ ] Test: Ensure `dbBind` supports positional and named parameters. (Source: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `r/tests/`. Issue: TBD
