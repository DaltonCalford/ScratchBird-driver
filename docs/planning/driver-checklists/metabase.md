# Metabase Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage in `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`. Issue: TBD


## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Metabase connects via JDBC drivers and expects a driver JAR registered with Metabase. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Metadata APIs must return stable results for schema sync. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: SQL dialect hints are required for Metabase query generation. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Metabase schema sync and field fingerprinting. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm native query mode executes parameterized SQL. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P3 (Future)
