# Metabase Driver Checklist

## P1 (Core)

- [x] Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage in `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: Metabase connects via JDBC drivers and expects a driver JAR registered with Metabase. (Source: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Constraint: Metadata APIs must return stable results for schema sync. (Source: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Constraint: SQL dialect hints are required for Metabase query generation. (Source: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Test: Validate Metabase schema sync and field fingerprinting. (Source: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)
- [ ] Test: Confirm native query mode executes parameterized SQL. (Source: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)


## P2 (Follow-ups)

- [x] Improve type mapping for complex SBWP types in `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`. Issue: TBD
