test_that("substitute positional params", {
  sql <- "SELECT * FROM t WHERE id = ? AND name = ?"
  out <- sb_substitute(sql, list(42, "Ada"))
  expect_equal(out, "SELECT * FROM t WHERE id = 42 AND name = 'Ada'")
})

test_that("substitute named params", {
  sql <- "SELECT * FROM users WHERE name = @name AND active = :active"
  out <- sb_substitute(sql, list(name = "Ada", active = TRUE))
  expect_equal(out, "SELECT * FROM users WHERE name = 'Ada' AND active = TRUE")
})

test_that("substitute binary params", {
  sql <- "SELECT ?"
  out <- sb_substitute(sql, list(as.raw(c(0x01, 0x02))))
  expect_equal(out, "SELECT X'0102'")
})
