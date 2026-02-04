# ODBC Driver Checklist

## P1 (Core)

- [ ] Expand type mapping to cover complex SBWP types where applicable in `odbc/src/odbc_client_bridge.cpp`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: SQLColumns must return a column list result set and includes ORDINAL_POSITION. (Source: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Constraint: Result set metadata is retrieved via SQLNumResultCols and SQLDescribeCol/SQLColAttribute. (Source: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Test: Validate SQLColumns result set columns (ORDINAL_POSITION, TYPE_NAME, etc.). (Source: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Test: Validate SQLDescribeCol and SQLNumResultCols behavior. (Source: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)
- [ ] Constraint: GeoServer PostGIS datastore expects host, port, database, schema, and credentials. (Source: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Constraint: Geometry columns must expose spatial reference metadata. (Source: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Constraint: Large feature layers should be streamed with paging. (Source: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Test: Validate datastore creation and layer publishing. (Source: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Test: Confirm WMS/WFS requests return expected features. (Source: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)
- [ ] Constraint: QGIS connects to PostGIS via the Data Source Manager and expects spatial metadata tables. (Source: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Constraint: Geometry column and SRID metadata must be consistent. (Source: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Constraint: Large spatial datasets require cursor-based fetching. (Source: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Test: Validate adding a PostGIS layer and rendering features. (Source: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Test: Confirm spatial indexes are recognized. (Source: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)
- [ ] Constraint: Qlik Sense uses ODBC connectors and expects DSN-based configuration. (Source: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Constraint: Metadata queries must be performant for script reloads. (Source: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Constraint: Unicode handling must preserve UTF-8 text. (Source: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Test: Validate Qlik load script `SELECT` executions. (Source: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Test: Confirm reloads handle large tables with paging. (Source: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)
- [ ] Constraint: Excel uses ODBC data sources and expects DSN configuration via the OS ODBC manager. (Source: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Constraint: The driver must expose stable column types for import. (Source: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Constraint: Result sets should avoid server-side cursor timeouts. (Source: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Test: Validate Excel data import and refresh workflows. (Source: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Test: Confirm wide tables and large row counts import correctly. (Source: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)
- [ ] Constraint: Tableau uses ODBC or JDBC drivers depending on the connector. (Source: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Constraint: The driver must expose accurate metadata for Tableau's data model. (Source: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Constraint: Large result sets must support paging and cancellation. (Source: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Test: Validate Tableau can publish and refresh extracts. (Source: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Test: Confirm custom SQL uses parameter binding without errors. (Source: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)
- [ ] Constraint: Power BI connects via ODBC data sources for custom databases. (Source: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Constraint: The driver must expose schema metadata and stable column types. (Source: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Constraint: Query folding should be supported where possible. (Source: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Test: Validate Power BI can import and refresh datasets. (Source: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Test: Confirm DirectQuery mode works with paging and timeouts. (Source: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)
- [ ] Constraint: MySQL Workbench migrations use ODBC drivers for source/target connectivity. (Source: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Constraint: Metadata discovery must support `SQLTables`, `SQLColumns`, and `SQLPrimaryKeys` equivalents. (Source: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Constraint: The driver must tolerate long-running introspection queries. (Source: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Test: Validate Workbench migration wizard completes schema introspection. (Source: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)
- [ ] Test: Confirm data copy works for large tables with paging. (Source: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)


## P2 (Follow-ups)

- [x] Removed fallback metadata queries; use only server-defined `sys.columns` and `sys.index_columns` columns in `odbc/src/odbc_handles.cpp`. Issue: N/A
- [ ] Add conformance tests for metadata + type coverage in `odbc/tests/`. Issue: TBD
