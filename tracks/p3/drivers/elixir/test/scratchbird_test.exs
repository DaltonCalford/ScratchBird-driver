# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

alias ScratchBird.Config

defmodule ScratchBirdConfigTest do
  use ExUnit.Case

  test "parses basic dsn" do
    cfg = Config.from_opts(url: "scratchbird://user:pass@localhost:3092/testdb")
    assert cfg.user == "user"
    assert cfg.password == "pass"
    assert cfg.host == "localhost"
    assert cfg.database == "testdb"
  end

  test "parses manager_proxy params and aliases" do
    cfg =
      Config.from_opts(
        url:
          "scratchbird://admin:secret@localhost:3090/mydb?" <>
            "frontdoormode=managed&mcp_auth_token=token&mcp_client_flags=7&mcp_auth_fast_path=false"
      )

    assert cfg.front_door_mode == "manager_proxy"
    assert cfg.manager_auth_token == "token"
    assert cfg.manager_client_flags == 7
    assert cfg.manager_auth_fast_path == false
  end

  test "rejects invalid front_door_mode" do
    assert_raise ArgumentError, fn ->
      Config.from_opts(url: "scratchbird://localhost:3092/db?front_door_mode=invalid")
    end
  end

  test "rejects invalid protocol" do
    assert_raise ArgumentError, fn ->
      Config.from_opts(url: "scratchbird://localhost:3092/db?protocol=postgres")
    end
  end
end
