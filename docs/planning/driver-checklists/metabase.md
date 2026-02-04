# Metabase Driver Checklist

## P1 (Core)
- [x] Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage in `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`. Issue: TBD


## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Metabase connects via JDBC drivers and expects a driver JAR registered with Metabase. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Constraint: Metadata APIs must return stable results for schema sync. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Constraint: SQL dialect hints are required for Metabase query generation. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Test: Validate Metabase schema sync and field fingerprinting. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Test: Confirm native query mode executes parameterized SQL. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [x] Improve type mapping for complex SBWP types in `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`. Issue: TBD

## P3 (Future)
