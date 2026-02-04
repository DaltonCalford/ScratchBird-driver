# Superset Driver Checklist

## P1 (Core)

- [ ] Map column types using `sys.columns.data_type_name` (remove numeric `data_type_id` fallback) in `scratchbird-superset-driver/scratchbird_superset/dialect.py`. Issue: TBD

## P2 (Follow-ups)

- [ ] Expand type mapping for arrays, ranges, geometry to richer SQLAlchemy types in `scratchbird-superset-driver/scratchbird_superset/dialect.py`. Issue: TBD
