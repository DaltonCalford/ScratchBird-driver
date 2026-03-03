# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
new_mock_connection <- function(client = NULL) {
  if (is.null(client)) {
    client <- new.env(parent = emptyenv())
    client$autocommit <- TRUE
  }
  ptr <- new.env(parent = emptyenv())
  ptr$client <- client
  methods::new("ScratchbirdConnection", ptr = ptr)
}

test_that("DBI transaction methods delegate and align autocommit", {
  client <- new.env(parent = emptyenv())
  client$autocommit <- TRUE
  conn <- new_mock_connection(client)
  begin_args <- NULL
  call_log <- character()

  local_mocked_bindings(
    sb_begin = function(client_arg, ...) {
      call_log <<- c(call_log, "begin")
      begin_args <<- list(...)
      expect_identical(client_arg, client)
      invisible(NULL)
    },
    sb_commit = function(client_arg, ...) {
      call_log <<- c(call_log, "commit")
      expect_identical(client_arg, client)
      invisible(NULL)
    },
    sb_rollback = function(client_arg, ...) {
      call_log <<- c(call_log, "rollback")
      expect_identical(client_arg, client)
      invisible(NULL)
    },
    sb_set_autocommit = function(client_arg, value) {
      client_arg$autocommit <- isTRUE(value)
      call_log <<- c(call_log, paste0("autocommit=", client_arg$autocommit))
      invisible(NULL)
    },
    .package = "scratchbird"
  )

  expect_true(DBI::dbBegin(conn, isolation_level = SB_ISOLATION_SERIALIZABLE))
  expect_equal(begin_args$isolation_level, SB_ISOLATION_SERIALIZABLE)
  expect_false(client$autocommit)

  expect_true(DBI::dbCommit(conn))
  expect_true(client$autocommit)

  expect_true(DBI::dbBegin(conn))
  expect_true(DBI::dbRollback(conn))
  expect_true(client$autocommit)
  expect_equal(
    call_log,
    c(
      "begin",
      "autocommit=FALSE",
      "commit",
      "autocommit=TRUE",
      "begin",
      "autocommit=FALSE",
      "rollback",
      "autocommit=TRUE"
    )
  )
})

test_that("transaction helpers emit expected message types", {
  client <- new.env(parent = emptyenv())
  client$sequence <- 0
  client$attachment_id <- raw(16)
  client$txn_id <- 0
  client$con <- list(socket = "mock")
  client$autocommit <- TRUE
  messages <- list()
  drain_calls <- 0L

  local_mocked_bindings(
    sb_send_message = function(client_arg, type, payload, flags = 0L, force_zero = FALSE) {
      messages[[length(messages) + 1]] <<- list(
        type = as.integer(type),
        payload = payload,
        flags = as.integer(flags),
        force_zero = force_zero
      )
      0L
    },
    sb_drain_until_ready = function(client_arg) {
      drain_calls <<- drain_calls + 1L
      invisible(NULL)
    },
    .package = "scratchbird"
  )

  sb_begin(client, isolation_level = SB_ISOLATION_SERIALIZABLE, wait = TRUE, timeout_ms = 500L)
  sb_commit(client, flags = 3L)
  sb_rollback(client, flags = 2L)
  sb_savepoint(client, "sp1")
  sb_release_savepoint(client, "sp1")
  sb_rollback_to_savepoint(client, "sp1")

  expect_equal(
    vapply(messages, function(msg) msg$type, integer(1)),
    c(
      SB_MSG_TXN_BEGIN,
      SB_MSG_TXN_COMMIT,
      SB_MSG_TXN_ROLLBACK,
      SB_MSG_TXN_SAVEPOINT,
      SB_MSG_TXN_RELEASE,
      SB_MSG_TXN_ROLLBACK_TO
    )
  )
  expect_identical(
    messages[[1]]$payload,
    build_txn_begin_payload(
      bitwOr(bitwOr(SB_TXN_FLAG_HAS_ISOLATION, SB_TXN_FLAG_HAS_WAIT), SB_TXN_FLAG_HAS_TIMEOUT),
      0L,
      0L,
      SB_ISOLATION_SERIALIZABLE,
      0L,
      0L,
      1L,
      500L
    )
  )
  expect_identical(messages[[2]]$payload, build_txn_commit_payload(3L))
  expect_identical(messages[[3]]$payload, build_txn_rollback_payload(2L))
  expect_identical(messages[[4]]$payload, build_txn_savepoint_payload("sp1"))
  expect_identical(messages[[5]]$payload, build_txn_release_payload("sp1"))
  expect_identical(messages[[6]]$payload, build_txn_rollback_to_payload("sp1"))
  expect_equal(drain_calls, 6L)
})

test_that("dbSendQuery/dbFetch/dbClearResult follow DBI result lifecycle", {
  conn <- new_mock_connection()
  result_env <- new.env(parent = emptyenv())
  result_env$done <- FALSE
  captured_sql <- NULL
  captured_params <- NULL
  fetch_n <- NULL
  clear_called <- FALSE

  local_mocked_bindings(
    sb_send_query = function(client, sql, params = NULL) {
      captured_sql <<- sql
      captured_params <<- params
      result_env
    },
    sb_fetch = function(result, n = -1) {
      fetch_n <<- n
      data.frame(value = 1L)
    },
    sb_clear_result = function(result) {
      clear_called <<- TRUE
      result$done <- TRUE
      result
    },
    .package = "scratchbird"
  )

  res <- DBI::dbSendQuery(conn, "SELECT ?::INTEGER", params = list(42L))
  expect_s4_class(res, "ScratchbirdResult")

  fetched <- DBI::dbFetch(res, n = 1)
  expect_equal(fetch_n, 1)
  expect_equal(fetched$value, 1L)

  expect_true(DBI::dbClearResult(res))
  expect_true(clear_called)
  expect_true(result_env$done)
  expect_equal(captured_sql, "SELECT ?::INTEGER")
  expect_equal(captured_params, list(42L))
})

test_that("dbExecute drains rows and returns integer row count", {
  conn <- new_mock_connection()
  result_env <- new.env(parent = emptyenv())
  result_env$rowcount <- 7
  captured_sql <- NULL
  captured_params <- NULL
  drained_n <- NULL

  local_mocked_bindings(
    sb_send_query = function(client, sql, params = NULL) {
      captured_sql <<- sql
      captured_params <<- params
      result_env
    },
    sb_fetch_rows = function(result, n = -1) {
      drained_n <<- n
      list(list(id = 1L))
    },
    .package = "scratchbird"
  )

  count <- DBI::dbExecute(conn, "UPDATE t SET v = ? WHERE id = ?", params = list("x", 1L))
  expect_type(count, "integer")
  expect_equal(count, 7L)
  expect_equal(drained_n, -1)
  expect_equal(captured_sql, "UPDATE t SET v = ? WHERE id = ?")
  expect_equal(captured_params, list("x", 1L))
})
