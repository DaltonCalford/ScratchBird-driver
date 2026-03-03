# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
new_metadata_mock_connection <- function() {
  ptr <- new.env(parent = emptyenv())
  ptr$client <- new.env(parent = emptyenv())
  methods::new("ScratchbirdConnection", ptr = ptr)
}

test_that("dbListTables lists schema-qualified names from metadata only", {
  conn <- new_metadata_mock_connection()
  tables <- data.frame(
    table_id = c(1L, 2L, 3L),
    schema_id = c(10L, 11L, 11L),
    table_name = c("events", "events", "users"),
    stringsAsFactors = FALSE
  )
  schemas <- data.frame(
    schema_id = c(10L, 11L),
    schema_name = c("sys", "users"),
    stringsAsFactors = FALSE
  )

  local_mocked_bindings(
    sb_get_query = function(client, sql, ...) {
      if (identical(sql, sb_metadata_tables_query())) return(tables)
      if (identical(sql, sb_metadata_schemas_query())) return(schemas)
      stop("unexpected SQL")
    },
    .package = "scratchbird"
  )

  listed <- DBI::dbListTables(conn)
  expect_equal(listed, c("sys.events", "users.events", "users.users"))
})

test_that("dbExistsTable resolves qualified table names against metadata", {
  conn <- new_metadata_mock_connection()
  tables <- data.frame(
    table_id = c(1L, 2L),
    schema_id = c(10L, 11L),
    table_name = c("events", "events"),
    stringsAsFactors = FALSE
  )
  schemas <- data.frame(
    schema_id = c(10L, 11L),
    schema_name = c("sys", "users"),
    stringsAsFactors = FALSE
  )

  local_mocked_bindings(
    sb_get_query = function(client, sql, ...) {
      if (identical(sql, sb_metadata_tables_query())) return(tables)
      if (identical(sql, sb_metadata_schemas_query())) return(schemas)
      stop("unexpected SQL")
    },
    .package = "scratchbird"
  )

  expect_true(DBI::dbExistsTable(conn, "users.events"))
  expect_true(DBI::dbExistsTable(conn, DBI::Id(schema = "sys", table = "events")))
  expect_false(DBI::dbExistsTable(conn, "audit.events"))
})

test_that("dbListFields filters metadata columns by schema and table", {
  conn <- new_metadata_mock_connection()
  tables <- data.frame(
    table_id = c(1L, 2L),
    schema_id = c(10L, 11L),
    table_name = c("events", "events"),
    stringsAsFactors = FALSE
  )
  schemas <- data.frame(
    schema_id = c(10L, 11L),
    schema_name = c("sys", "users"),
    stringsAsFactors = FALSE
  )
  columns <- data.frame(
    table_id = c(1L, 1L, 2L, 2L),
    column_name = c("id", "payload", "id", "email"),
    ordinal_position = c(1L, 2L, 1L, 2L),
    stringsAsFactors = FALSE
  )

  local_mocked_bindings(
    sb_get_query = function(client, sql, ...) {
      if (identical(sql, sb_metadata_tables_query())) return(tables)
      if (identical(sql, sb_metadata_schemas_query())) return(schemas)
      if (identical(sql, sb_metadata_columns_query())) return(columns)
      stop("unexpected SQL")
    },
    .package = "scratchbird"
  )

  fields <- DBI::dbListFields(conn, DBI::Id(schema = "users", table = "events"))
  expect_equal(fields, c("id", "email"))
})
