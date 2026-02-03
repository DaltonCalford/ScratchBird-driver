# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

ExUnit.start()

alias ScratchBird.Config

defmodule ScratchBirdConfigTest do
  use ExUnit.Case

  test "parses basic dsn" do
    cfg = Config.parse_dsn("scratchbird://user:pass@localhost:3092/testdb")
    assert cfg.user == "user"
    assert cfg.password == "pass"
    assert cfg.host == "localhost"
    assert cfg.database == "testdb"
  end
end
