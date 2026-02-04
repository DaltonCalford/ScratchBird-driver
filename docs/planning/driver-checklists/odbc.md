# ODBC Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: SQLColumns must return a column list result set and includes ORDINAL_POSITION. (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Constraint: Result set metadata is retrieved via SQLNumResultCols and SQLDescribeCol/SQLColAttribute. (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Test: Validate SQLColumns result set columns (ORDINAL_POSITION, TYPE_NAME, etc.). (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Test: Validate SQLDescribeCol and SQLNumResultCols behavior. (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Expand type mapping to cover complex SBWP types where applicable in `odbc/src/odbc_client_bridge.cpp`. Issue: TBD (Sources: ``)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [ ] Constraint: Qlik Sense uses ODBC connectors and expects DSN-based configuration. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Constraint: Metadata queries must be performant for script reloads. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Constraint: Unicode handling must preserve UTF-8 text. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Test: Validate Qlik load script `SELECT` executions. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Test: Confirm reloads handle large tables with paging. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Constraint: Excel uses ODBC data sources and expects DSN configuration via the OS ODBC manager. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Constraint: The driver must expose stable column types for import. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Constraint: Result sets should avoid server-side cursor timeouts. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Test: Validate Excel data import and refresh workflows. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Test: Confirm wide tables and large row counts import correctly. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Constraint: Tableau uses ODBC or JDBC drivers depending on the connector. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Constraint: The driver must expose accurate metadata for Tableau's data model. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Constraint: Large result sets must support paging and cancellation. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Test: Validate Tableau can publish and refresh extracts. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Test: Confirm custom SQL uses parameter binding without errors. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Constraint: Power BI connects via ODBC data sources for custom databases. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Constraint: The driver must expose schema metadata and stable column types. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Constraint: Query folding should be supported where possible. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Test: Validate Power BI can import and refresh datasets. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Test: Confirm DirectQuery mode works with paging and timeouts. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Constraint: MySQL Workbench migrations use ODBC drivers for source/target connectivity. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Constraint: Metadata discovery must support `SQLTables`, `SQLColumns`, and `SQLPrimaryKeys` equivalents. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Constraint: The driver must tolerate long-running introspection queries. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Test: Validate Workbench migration wizard completes schema introspection. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Test: Confirm data copy works for large tables with paging. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Add conformance tests for metadata + type coverage in `odbc/tests/`. Issue: TBD (Sources: ``)
## P3 (Future)

### Integration Appendix Tasks

- [ ] Constraint: GeoServer PostGIS datastore expects host, port, database, schema, and credentials. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Constraint: Geometry columns must expose spatial reference metadata. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Constraint: Large feature layers should be streamed with paging. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Test: Validate datastore creation and layer publishing. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Test: Confirm WMS/WFS requests return expected features. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Constraint: QGIS connects to PostGIS via the Data Source Manager and expects spatial metadata tables. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Constraint: Geometry column and SRID metadata must be consistent. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Constraint: Large spatial datasets require cursor-based fetching. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Test: Validate adding a PostGIS layer and rendering features. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Test: Confirm spatial indexes are recognized. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)