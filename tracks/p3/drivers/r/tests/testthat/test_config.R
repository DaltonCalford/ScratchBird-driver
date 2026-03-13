# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
test_that("parse URI config", {
  cfg <- sb_config("scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd")
  expect_equal(cfg$host, "localhost")
  expect_equal(cfg$port, 3092L)
  expect_equal(cfg$database, "mydb")
  expect_equal(cfg$user, "user")
  expect_equal(cfg$password, "pass")
  expect_equal(cfg$sslmode, "require")
  expect_equal(cfg$connect_timeout_ms, 3000L)
  expect_equal(cfg$application_name, "app")
  expect_false(cfg$binary_transfer)
  expect_equal(cfg$compression, "zstd")
})

test_that("parse key-value config", {
  cfg <- sb_config("Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7")
  expect_equal(cfg$host, "server")
  expect_equal(cfg$port, 4000L)
  expect_equal(cfg$database, "db")
  expect_equal(cfg$user, "me")
  expect_equal(cfg$password, "secret")
  expect_equal(cfg$connect_timeout_ms, 5000L)
  expect_equal(cfg$socket_timeout_ms, 7000L)
})

test_that("parse manager proxy params", {
  cfg <- sb_config("scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7")
  expect_equal(cfg$front_door_mode, "manager_proxy")
  expect_equal(cfg$manager_auth_token, "token")
  expect_equal(cfg$manager_client_flags, 7L)
})

test_that("invalid front door mode errors", {
  expect_error(sb_config("scratchbird://localhost:3092/db?front_door_mode=invalid"), "front_door_mode must be direct or manager_proxy")
})
