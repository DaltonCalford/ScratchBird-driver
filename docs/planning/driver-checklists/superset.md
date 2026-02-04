# Superset Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

- [x] Map column types using `sys.columns.data_type_name` (remove numeric `data_type_id` fallback) in `scratchbird-superset-driver/scratchbird_superset/dialect.py`. Issue: TBD

## P2 (Follow-ups)

- [x] Expand type mapping for arrays, ranges, geometry to richer SQLAlchemy types in `scratchbird-superset-driver/scratchbird_superset/dialect.py`. Issue: TBD

## P3 (Future)