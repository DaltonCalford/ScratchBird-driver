# R Driver API Reference

## Package

- Package: `scratchbird`
- DBI driver: `Scratchbird()`

## Core DBI Methods

- `dbConnect(Scratchbird(), dsn, ...)`
- `dbDisconnect(conn)`
- `dbGetQuery(conn, sql, ...)`
- `dbSendQuery(conn, sql, ...)` + `dbFetch()`
- `dbExecute(conn, sql, ...)`
- `dbListTables(conn)`
- `dbExistsTable(conn, name)`
- `dbListFields(conn, name)`
- `dbColumnInfo(res)`

## Metadata Helpers

- `sb_metadata_schemas_query()`
- `sb_metadata_tables_query()`
- `sb_metadata_columns_query()`
- `sb_metadata_indexes_query()`
- `sb_metadata_index_columns_query()`
- `sb_metadata_constraints_query()`
- `sb_metadata_procedures_query()`
- `sb_metadata_functions_query()`
- `sb_metadata_schema_paths_for_navigation(...)`
- `sb_metadata_build_schema_tree(...)`
- `sb_metadata_build_schema_tree_rows(...)`

## Wrapper Types

- `sb_jsonb()`
- `sb_geometry()`
- `sb_range()`

## SBWP v1.1 Extensions

Low-level helpers (in addition to DBI):

- `sb_begin(conn, ...)`, `sb_commit(conn, flags)`, `sb_rollback(conn, flags)`
- `sb_savepoint(conn, name)`, `sb_release_savepoint(conn, name)`,
  `sb_rollback_to_savepoint(conn, name)`
- `sb_set_option(conn, name, value)`
- `sb_ping(conn)`, `sb_terminate(conn)`, `sb_cancel(conn)`
- `sb_subscribe(conn, channel, subscribe_type, filter_expr)`,
  `sb_unsubscribe(conn, channel)`
- `sb_execute_sblr(conn, hash, bytecode, params)`
- `sb_stream_control(conn, control_type, window_size, timeout_ms)`
- `sb_attach_create(conn, emulation_mode, db_name)`, `sb_attach_detach(conn)`,
  `sb_attach_list(conn)`
- `sb_on_notification(conn, handler)`
- `sb_get_last_plan(conn)`, `sb_get_last_sblr(conn)`

## Errors

Errors map to SQLSTATE codes per
[DRIVER_ERROR_MAPPING.md](../specifications/DRIVER_ERROR_MAPPING.md).
