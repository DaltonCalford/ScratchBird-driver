# Metadata and Schema Contract (ScratchBird Drivers)

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define how drivers must obtain schema and metadata information from ScratchBird
and how schema search paths are applied for native connections.

## Authoritative References

- `ScratchBird/docs/specifications/catalog/README.md`
- `ScratchBird/docs/specifications/catalog/SCHEMA_PATH_RESOLUTION.md`
- `ScratchBird/docs/specifications/catalog/SYSTEM_CATALOG_STRUCTURE.md`

## Schema/Search Path

1. Drivers must support a configurable default schema or search path.
2. On connection, drivers must set the search path using the native mechanism
   defined in the schema path spec (e.g., SET SCHEMA or SET SEARCH_PATH).
3. If no explicit schema is provided, the server default applies.

## Required Metadata Queries

Drivers must use the `sys` catalog views for metadata unless a dialect-specific
view is required by the API (e.g., information_schema for some language drivers).
The queries below are the minimum baseline and should be treated as stable.

1. Schemas
   - SELECT schema_id, schema_name, owner_id, default_tablespace_id
     FROM sys.schemas WHERE is_valid = 1

2. Tables
   - SELECT table_id, schema_id, table_name, table_type, owner_id
     FROM sys.tables WHERE is_valid = 1

3. Columns
   - SELECT column_id, table_id, column_name, data_type_id, data_type_name,
     ordinal_position, is_nullable, default_value, domain_id, collation_id,
     charset_id, is_identity, is_generated, generation_expression
     FROM sys.columns WHERE is_valid = 1

4. Indexes
   - SELECT index_id, table_id, index_name, index_type, is_unique
     FROM sys.indexes WHERE is_valid = 1

5. Index Columns
   - SELECT index_id, column_id, column_name, ordinal_position, is_included
     FROM sys.index_columns

6. Constraints
   - SELECT constraint_id, table_id, constraint_name, constraint_type
     FROM sys.constraints WHERE is_valid = 1

7. Routines
   - SELECT procedure_id, schema_id, procedure_name, routine_type
     FROM sys.procedures WHERE is_valid = 1
   - SELECT function_id, schema_id, function_name
     FROM sys.functions WHERE is_valid = 1

## JDBC/ODBC Metadata

Drivers that expose JDBC/ODBC metadata must map the sys catalog data into the
standard metadata result shapes (DatabaseMetaData, INFORMATION_SCHEMA, etc.).

## Monitoring Views

Runtime monitoring views (e.g., `sys.sessions`, `sys.transactions`, `sys.locks`,
`sys.statements`, `sys.io_stats`, `sys.performance`, `sys.jobs`) are defined in
`docs/specifications/DRIVER_MONITORING_VIEW_SUPPORT.md`. Drivers must not hide
the `sys` schema and should surface these views as read-only system views in
metadata APIs where applicable.

## Notes

If any required sys.* view is missing in the server, a specification update in
ScratchBird must define the view or table required for driver metadata queries.
