# Driver Metadata Mapping (JDBC/ODBC and Language Drivers)

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define the minimum metadata mapping required for JDBC and ODBC drivers
using ScratchBird sys.* catalog views, plus baseline expectations for
other language drivers.

## Binary-Only Requirement

Metadata queries must request binary results and decode using SBWP
binary formats.

## Required sys.* Views

See:
- `ScratchBird/docs/specifications/drivers/DRIVER_METADATA_QUERY_CONTRACT.md`

## SQLSTATE Codes (Metadata)

- 42P01: undefined table/view (missing sys.* view)
- 42703: undefined column (schema mismatch)

## JDBC DatabaseMetaData (Minimum)

### getSchemas

Map to sys.schemas:
- TABLE_SCHEM -> schema_name
- TABLE_CATALOG -> current database name

### getTables

Map to sys.tables:
- TABLE_SCHEM -> schema_name (join sys.schemas)
- TABLE_NAME -> table_name
- TABLE_TYPE -> table_type (TABLE/VIEW/SYSTEM TABLE)

### getColumns

Map to sys.columns:
- TABLE_SCHEM -> schema_name
- TABLE_NAME -> table_name
- COLUMN_NAME -> column_name
- DATA_TYPE -> JDBC type code (from data_type_id)
- TYPE_NAME -> ScratchBird type name
- ORDINAL_POSITION -> ordinal_position
- IS_NULLABLE -> is_nullable

## ODBC (SQLTables/SQLColumns)

### SQLTables

- TABLE_CAT -> current database name
- TABLE_SCHEM -> schema_name
- TABLE_NAME -> table_name
- TABLE_TYPE -> table_type

### SQLColumns

- TABLE_SCHEM -> schema_name
- TABLE_NAME -> table_name
- COLUMN_NAME -> column_name
- DATA_TYPE -> ODBC SQL type
- TYPE_NAME -> ScratchBird type name
- COLUMN_SIZE -> type size
- NULLABLE -> is_nullable

## Per-Language Metadata Expectations

### Go

- Column metadata via Rows.ColumnTypes.
- Provide helper queries for schemas/tables/columns using sys.* views.

### Node.js/TypeScript

- Field metadata via QueryResult.fields.
- Provide helper queries for sys.schemas/sys.tables/sys.columns.

### Python

- Cursor.description must be populated from row description.
- Provide helper queries for sys.* metadata when requested.

### Ruby

- Result#columns and Result#fields must reflect sys.* metadata.
- Provide helper queries for sys.* metadata.

### Rust

- Column metadata via Column struct in QueryResult.
- Provide helper functions for sys.* metadata.

### PHP

- ResultStream::columns returns column metadata.
- Provide helper queries for sys.* metadata.

### R

- Provide metadata helpers (schemas/tables/columns) returning data.frame.

### Pascal/Delphi

- Populate dataset field metadata from sys.* views.

### .NET

- Use DbDataReader.GetSchemaTable for column metadata.
- Provide helper queries for sys.* metadata.

### JDBC

- Implement DatabaseMetaData methods using sys.* views.
