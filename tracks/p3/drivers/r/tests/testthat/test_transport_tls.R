# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

test_that("native TLS transport path is active", {
  err <- tryCatch(
    {
      sb_connect("scratchbird://user:pass@127.0.0.1:1/testdb")
      ""
    },
    error = function(e) conditionMessage(e)
  )
  expect_false(grepl("TLS transport is not implemented", err, fixed = TRUE))
  expect_true(grepl("TCP connection|failed|timeout|refused|TLS", err, ignore.case = TRUE))
})
