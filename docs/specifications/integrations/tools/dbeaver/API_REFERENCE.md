# DBeaver Integration API Reference

Status: Updated 2026-03-13
Priority: P0
Category: Database Tool

## IDs and Packaging

- plugin ID: `org.jkiss.dbeaver.ext.scratchbird`
- planned UI plugin ID: `org.jkiss.dbeaver.ext.scratchbird.ui`
- feature ID: `org.jkiss.dbeaver.ext.scratchbird.feature`
- driver ID: `scratchbird_jdbc`
- datasource provider ID: `scratchbird`

## Driver Binding

- JDBC class: `com.scratchbird.jdbc.SBDriver`
- sample URL: `jdbc:scratchbird://{host}[:{port}]/{database}`
- default port: `3092`
- default Maven reference: `maven:/com.scratchbird:scratchbird-jdbc:RELEASE`

## Source Paths

- adapter lane:
  `tracks/alpha/integrations/scratchbird-dbeaver-driver/`
- JDBC lane:
  `tracks/p3/drivers/jdbc/`

## DBeaver Feature Families In Scope

- core provider/model:
  - `org.jkiss.dbeaver.dataSourceProvider`
  - `org.jkiss.dbeaver.generic.meta`
- SQL editor:
  - `org.jkiss.dbeaver.sqlDialect`
  - `org.eclipse.core.runtime.adapters` for dialect/text-rule integration where needed
- object editing:
  - `org.jkiss.dbeaver.objectManager`
  - `org.jkiss.dbeaver.databaseEditor`
- connection/auth/network:
  - `org.jkiss.dbeaver.dataSourceView`
  - `org.jkiss.dbeaver.dataSourceAuth`
  - `org.jkiss.dbeaver.networkHandler`
  - `org.jkiss.dbeaver.ui.propertyConfigurator`
- data/value handling:
  - `org.jkiss.dbeaver.dataTypeProvider`
  - `org.jkiss.dbeaver.dataManager`
- operational integration:
  - `org.jkiss.dbeaver.task`
  - `org.jkiss.dbeaver.tools`
  - `org.jkiss.dbeaver.task.ui`
  - `org.jkiss.dbeaver.dashboard`
  - `org.jkiss.dbeaver.sqlGenerator`
  - `org.jkiss.dbeaver.sqlCommand`
  - `org.jkiss.dbeaver.sqlBackup`

## Build / Install Scripts

- stock-update-site build:
  `tracks/alpha/integrations/scratchbird-dbeaver-driver/scripts/build-p2-update-site.sh`
- DBeaver source-checkout install:
  `tracks/alpha/integrations/scratchbird-dbeaver-driver/scripts/install-into-dbeaver.sh`

## Notable JDBC Compatibility Knob

- property: `metadataExpandSchemaParents`
- aliases:
  - `metadata_expand_schema_parents`
  - `expandSchemaParents`
  - `dbeaver_expand_schema_parents`
- default: `false`
- purpose:
  - optionally emit parent schema segments through
    `DatabaseMetaData.getSchemas()`
