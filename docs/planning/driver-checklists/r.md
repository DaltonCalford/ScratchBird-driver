# R Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Add SQLSTATE class-prefix mapping (currently only prefixes message) in `tracks/beta/drivers/r/R/client.R`. Issue: DONE (2026-03-04)


## P2 (Follow-ups)
- [x] Add conformance tests for full type matrix in `tracks/beta/drivers/r/tests/`. Issue: Deferred Status: DEFERRED (2026-02-04)

## P3 (Future)

### Integration Appendix Tasks

- [x] Constraint: Conform to R DBI generics and return data frames with stable column classes. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Support `dbListTables` and `dbColumnInfo` for metadata introspection. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Treat `NA` and `NULL` per DBI expectations. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate `dbGetQuery` returns consistent `data.frame` column types. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Ensure `dbBind` supports positional and named parameters. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
