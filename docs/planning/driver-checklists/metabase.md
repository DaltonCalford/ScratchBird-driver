# Metabase Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage in `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`. Issue: TBD


## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Metabase connects via JDBC drivers and expects a driver JAR registered with Metabase. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Constraint: Metadata APIs must return stable results for schema sync. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Constraint: SQL dialect hints are required for Metabase query generation. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Test: Validate Metabase schema sync and field fingerprinting. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Test: Confirm native query mode executes parameterized SQL. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
## P3 (Future)