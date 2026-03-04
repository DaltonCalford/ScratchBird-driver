# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

new_mock_connection_for_res <- function(client = NULL) {
  if (is.null(client)) {
    client <- new.env(parent = emptyenv())
    client$autocommit <- TRUE
  }
  ptr <- new.env(parent = emptyenv())
  ptr$client <- client
  methods::new("ScratchbirdConnection", ptr = ptr)
}

build_server_error_payload_for_res <- function(
  sqlstate = "",
  message = "query failed",
  detail = "",
  hint = "",
  severity = "ERROR"
) {
  fields <- list(S = severity, C = sqlstate, M = message, D = detail, H = hint)
  payload <- raw()
  for (field in names(fields)) {
    value <- fields[[field]]
    if (!nzchar(value)) next
    payload <- c(payload, charToRaw(field), charToRaw(value), as.raw(0x00))
  }
  c(payload, as.raw(0x00))
}

test_that("sb_disconnect is idempotent and closes socket once", {
  client <- new.env(parent = emptyenv())
  client$con <- list(socket = "mock")
  non_null_close_calls <- 0L
  null_close_calls <- 0L

  local_mocked_bindings(
    sb_socket_close = function(con) {
      if (is.null(con)) {
        null_close_calls <<- null_close_calls + 1L
      } else {
        non_null_close_calls <<- non_null_close_calls + 1L
      }
      invisible(NULL)
    },
    .package = "scratchbird"
  )

  sb_disconnect(client)
  sb_disconnect(client)

  expect_equal(non_null_close_calls, 1L)
  expect_equal(null_close_calls, 1L)
  expect_null(client$con)
})

test_that("dbDisconnect returns TRUE on repeated calls and only closes once", {
  client <- new.env(parent = emptyenv())
  client$con <- list(socket = "mock")
  conn <- new_mock_connection_for_res(client)
  non_null_close_calls <- 0L
  null_close_calls <- 0L

  local_mocked_bindings(
    sb_socket_close = function(con) {
      if (is.null(con)) {
        null_close_calls <<- null_close_calls + 1L
      } else {
        non_null_close_calls <<- non_null_close_calls + 1L
      }
      invisible(NULL)
    },
    .package = "scratchbird"
  )

  expect_true(DBI::dbDisconnect(conn))
  expect_true(DBI::dbDisconnect(conn))
  expect_equal(non_null_close_calls, 1L)
  expect_equal(null_close_calls, 1L)
  expect_null(client$con)
})

test_that("dbClearResult is idempotent after completion", {
  result_env <- new.env(parent = emptyenv())
  result_env$done <- FALSE
  res <- methods::new("ScratchbirdResult", result = result_env)

  expect_true(DBI::dbClearResult(res))
  expect_true(DBI::dbClearResult(res))
  expect_true(result_env$done)
})

test_that("result cleanup can run after server error during row fetch", {
  client <- new.env(parent = emptyenv())
  client$notification_handlers <- list()
  client$parameters <- list()
  client$con <- list(socket = "mock")

  result <- new.env(parent = emptyenv())
  result$client <- client
  result$columns <- list()
  result$rowcount <- -1
  result$command_tag <- ""
  result$done <- FALSE
  result$page_size <- 0L

  local_mocked_bindings(
    sb_recv_message = function(client_arg) {
      list(
        type = SB_MSG_ERROR,
        payload = build_server_error_payload_for_res(
          sqlstate = "23505",
          message = "duplicate key value violates unique constraint"
        )
      )
    },
    .package = "scratchbird"
  )

  expect_error(
    sb_result_next_row(result),
    "\\[23505\\] duplicate key value violates unique constraint"
  )
  expect_false(result$done)

  sb_clear_result(result)
  expect_true(result$done)
})
