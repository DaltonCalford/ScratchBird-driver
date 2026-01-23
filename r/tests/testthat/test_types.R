test_that("decode UUID", {
  bytes <- as.raw(strtoi(substring("12345678123456781234567812345678", seq(1, 31, 2), seq(2, 32, 2)), 16L))
  out <- decode_value(SB_OID_UUID, bytes, SB_FORMAT_BINARY)
  expect_equal(out, "12345678-1234-5678-1234-567812345678")
})

test_that("decode vector", {
  payload <- encode_length_prefixed(charToRaw("[1,2,3]"))
  out <- decode_value(SB_OID_SB_VECTOR, payload, SB_FORMAT_BINARY)
  expect_equal(length(out), 3)
})
