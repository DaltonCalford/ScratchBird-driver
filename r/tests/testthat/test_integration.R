test_that("integration query", {
  dsn <- Sys.getenv("SCRATCHBIRD_R_URL")
  if (dsn == "") {
    skip("SCRATCHBIRD_R_URL not set")
  }
  client <- sb_connect(dsn)
  on.exit(sb_disconnect(client), add = TRUE)
  result <- sb_query(client, "SELECT 1")
  expect_true(length(result$rows) > 0)
})

test_that("integration prepare bind", {
  dsn <- Sys.getenv("SCRATCHBIRD_R_URL")
  if (dsn == "") {
    skip("SCRATCHBIRD_R_URL not set")
  }
  client <- sb_connect(dsn)
  on.exit(sb_disconnect(client), add = TRUE)
  result <- sb_query(client, "SELECT ?::INTEGER", list(42))
  expect_true(length(result$rows) > 0)
  expect_equal(result$rows[[1]][[1]], 42)
})

test_that("integration types fixture", {
  dsn <- Sys.getenv("SCRATCHBIRD_R_URL")
  if (dsn == "") {
    skip("SCRATCHBIRD_R_URL not set")
  }
  client <- sb_connect(dsn)
  on.exit(sb_disconnect(client), add = TRUE)
  result <- sb_query(client, "SELECT * FROM sb_conformance.type_coverage")
  expect_true(length(result$rows) > 0)
})
