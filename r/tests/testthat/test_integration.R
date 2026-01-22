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
