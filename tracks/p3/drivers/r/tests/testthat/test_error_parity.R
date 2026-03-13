# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
build_server_error_payload <- function(
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

test_that("SQLSTATE mapping supports exact and class-prefix fallbacks", {
  expect_equal(sb_sqlstate_error_class("23505"), "scratchbird_integrity_error")
  expect_equal(sb_sqlstate_error_class("08ZZZ"), "scratchbird_connection_error")
  expect_equal(sb_sqlstate_error_class("22ZZZ"), "scratchbird_data_error")
  expect_equal(sb_sqlstate_error_class("XX999"), "scratchbird_internal_error")
  expect_null(sb_sqlstate_error_class("ZZZZZ"))
  expect_null(sb_sqlstate_error_class("2200"))
})

test_that("query errors expose SQLSTATE metadata with typed classes", {
  payload <- build_server_error_payload(
    sqlstate = "23505",
    message = "duplicate key value violates unique constraint",
    detail = "Key (id)=(1) already exists",
    hint = "Use a different key"
  )

  err <- tryCatch(
    {
      sb_raise_query_error(payload)
      NULL
    },
    error = function(e) e
  )

  expect_s3_class(err, "scratchbird_integrity_error")
  expect_s3_class(err, "scratchbird_sqlstate_error")
  expect_s3_class(err, "scratchbird_error")
  expect_equal(err$sqlstate, "23505")
  expect_equal(err$detail, "Key (id)=(1) already exists")
  expect_equal(err$hint, "Use a different key")
  expect_match(conditionMessage(err), "\\[23505\\]")
})

test_that("unknown SQLSTATE classes fall back to generic scratchbird errors", {
  payload <- build_server_error_payload(sqlstate = "ZZZZZ", message = "unmapped failure")
  err <- tryCatch(
    {
      sb_raise_query_error(payload)
      NULL
    },
    error = function(e) e
  )

  expect_s3_class(err, "scratchbird_sqlstate_error")
  expect_s3_class(err, "scratchbird_error")
  expect_false(inherits(err, "scratchbird_data_error"))
  expect_match(conditionMessage(err), "\\[ZZZZZ\\]")
})

test_that("errors without SQLSTATE stay generic and omit SQLSTATE prefix", {
  payload <- build_server_error_payload(sqlstate = "", message = "query failed")
  err <- tryCatch(
    {
      sb_raise_query_error(payload)
      NULL
    },
    error = function(e) e
  )

  expect_s3_class(err, "scratchbird_error")
  expect_false(inherits(err, "scratchbird_sqlstate_error"))
  expect_equal(err$sqlstate, "")
  expect_equal(conditionMessage(err), "query failed")
})
