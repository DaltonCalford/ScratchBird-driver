# QGIS Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| QGIS connects to PostGIS via the Data Source Manager and expects spatial metadata tables. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Geometry column and SRID metadata must be consistent. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Large spatial datasets require cursor-based fetching. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate adding a PostGIS layer and rendering features. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm spatial indexes are recognized. | Yes | Deferred | Test criteria from SPECIFICATION.md |
