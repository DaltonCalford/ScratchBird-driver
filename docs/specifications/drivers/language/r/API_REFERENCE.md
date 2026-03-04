# R Driver API Reference

Status: Active (beta lane)
Priority: P2

## Driver Construction

- `Scratchbird()`
- `DBI::dbConnect(Scratchbird(), dsn, ...)`
- `DBI::dbCanConnect(Scratchbird(), dsn, ...)`
- `DBI::dbDisconnect(conn)`
- `DBI::dbIsValid(conn)`

## DBI Query and Execute

- `DBI::dbGetQuery(conn, statement, ...)`
- `DBI::dbSendQuery(conn, statement, ...)`
- `DBI::dbFetch(result, n = -1, ...)`
- `DBI::dbClearResult(result, ...)`
- `DBI::dbGetRowsAffected(result, ...)`
- `DBI::dbExecute(conn, statement, ...)`

## DBI Transaction Surface

- `DBI::dbBegin(conn, ...)`
- `DBI::dbCommit(conn, ...)`
- `DBI::dbRollback(conn, ...)`

## DBI Metadata Surface

- `DBI::dbListTables(conn, ...)`
- `DBI::dbExistsTable(conn, name, ...)` (`character`, `Id`, `SQL`)
- `DBI::dbListFields(conn, name, ...)` (`character`, `Id`, `SQL`)

These methods are metadata-driven and use metadata helper queries/shaping in-lane.

## Metadata Helpers

- `sb_metadata_schemas_query()`
- `sb_metadata_tables_query()`
- `sb_metadata_columns_query()`
- `sb_metadata_indexes_query()`
- `sb_metadata_index_columns_query()`
- `sb_metadata_constraints_query()`
- `sb_metadata_procedures_query()`
- `sb_metadata_functions_query()`
- `sb_metadata_schema_paths_for_navigation(schema_names, expand_schema_parents = FALSE)`
- `sb_metadata_build_schema_tree(schema_names, database = "", expand_schema_parents = FALSE)`
- `sb_metadata_build_schema_tree_rows(schema_names, database = "", expand_schema_parents = FALSE)`

## Low-Level SBWP Extensions

- `sb_begin`, `sb_commit`, `sb_rollback`
- `sb_savepoint`, `sb_release_savepoint`, `sb_rollback_to_savepoint`
- `sb_set_option`, `sb_ping`, `sb_terminate`, `sb_cancel`
- `sb_subscribe`, `sb_unsubscribe`
- `sb_execute_sblr`
- `sb_stream_control`
- `sb_attach_create`, `sb_attach_detach`, `sb_attach_list`
- `sb_on_notification`, `sb_get_last_plan`, `sb_get_last_sblr`

## Errors

- SQLSTATE and protocol errors are surfaced from `sb_raise_query_error(...)`.
- Typed DBI condition-class layering remains partial in this lane.
