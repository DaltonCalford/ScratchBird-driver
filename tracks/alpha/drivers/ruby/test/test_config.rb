# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestConfig < Minitest::Test
  def test_parse_uri
    cfg = Scratchbird::Config.parse(
      "scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd"
    )
    assert_equal "localhost", cfg.host
    assert_equal 3092, cfg.port
    assert_equal "mydb", cfg.database
    assert_equal "user", cfg.user
    assert_equal "pass", cfg.password
    assert_equal "require", cfg.sslmode
    assert_equal 3000, cfg.connect_timeout_ms
    assert_equal "app", cfg.application_name
    assert_equal false, cfg.binary_transfer
    assert_equal "zstd", cfg.compression
  end

  def test_parse_key_value
    cfg = Scratchbird::Config.parse(
      "Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7"
    )
    assert_equal "server", cfg.host
    assert_equal 4000, cfg.port
    assert_equal "db", cfg.database
    assert_equal "me", cfg.user
    assert_equal "secret", cfg.password
    assert_equal 5000, cfg.connect_timeout_ms
    assert_equal 7000, cfg.socket_timeout_ms
  end

  def test_parse_manager_proxy_params
    cfg = Scratchbird::Config.parse(
      "scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7"
    )
    assert_equal "manager_proxy", cfg.front_door_mode
    assert_equal "token", cfg.manager_auth_token
    assert_equal 7, cfg.manager_client_flags
  end

  def test_parse_metadata_expand_schema_parents_aliases
    cfg = Scratchbird::Config.parse(
      "scratchbird://user:pass@localhost:3092/mydb?metadata_expand_schema_parents=true"
    )
    assert_equal true, cfg.metadata_expand_schema_parents

    kv = Scratchbird::Config.parse("Host=server;Database=db;User=me;Expand_Schema_Parents=1")
    assert_equal true, kv.metadata_expand_schema_parents
  end

  def test_invalid_front_door_mode_raises
    assert_raises(ArgumentError) do
      Scratchbird::Config.parse("scratchbird://localhost:3092/db?front_door_mode=invalid")
    end
  end
end
