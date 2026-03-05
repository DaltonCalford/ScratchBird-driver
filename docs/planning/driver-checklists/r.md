# R Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Add SQLSTATE class-prefix mapping (currently only prefixes message) in `tracks/beta/drivers/r/R/client.R`. Issue: DONE (2026-03-04)
- [x] Expand env-gated live integration coverage for manager-proxy connect/query, transaction/savepoint lifecycle, metadata wrappers/tree rows, ping roundtrip, and post-error usability in `tracks/beta/drivers/r/tests/testthat/test_integration.R`. Issue: DONE (2026-03-05)
- [x] Fix integration cancel-path assertion to drain a real result and validate error cleanup (`sb_execute_query` + `sb_fetch_rows`) in `tracks/beta/drivers/r/tests/testthat/test_integration.R`. Issue: DONE (2026-03-05)


## P2 (Follow-ups)
- [x] Add conformance tests for full type matrix in `tracks/beta/drivers/r/tests/`. Issue: DONE (2026-03-04)
- [x] Add deterministic execution lifecycle tests for extended-query message order, parameter-mismatch failure handling, and portal-suspension resume flow in `tracks/beta/drivers/r/tests/testthat/test_exec_lifecycle.R`. Issue: DONE (2026-03-05)
- [x] Add DBI `dbColumnInfo` support (with metadata priming before fetch) in `tracks/beta/drivers/r/R/dbi.R` and `tracks/beta/drivers/r/R/client.R`. Issue: DONE (2026-03-05)
- [x] Stabilize `sb_rows_to_df` typed column conversion across decoded scalar families in `tracks/beta/drivers/r/R/client.R`. Issue: DONE (2026-03-05)
- [x] Add env-gated integration coverage for incremental fetch lifecycle with `fetch_size` in `tracks/beta/drivers/r/tests/testthat/test_integration.R`. Issue: DONE (2026-03-05)
- [x] Add env-gated metadata wrapper-family integration smoke coverage (indexes/index-columns/constraints/procedures/functions) in `tracks/beta/drivers/r/tests/testthat/test_integration.R`. Issue: DONE (2026-03-05)

## P3 (Future)

### Integration Appendix Tasks

- [x] Constraint: Conform to R DBI generics and return data frames with stable column classes. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DONE (2026-03-05)
- [x] Constraint: Support `dbListTables` and `dbColumnInfo` for metadata introspection. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DONE (2026-03-05)
- [x] Constraint: Treat `NA` and `NULL` per DBI expectations. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate `dbGetQuery` returns consistent `data.frame` column types. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Ensure `dbBind` supports positional and named parameters. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
