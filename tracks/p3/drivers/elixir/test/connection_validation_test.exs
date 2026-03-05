# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdConnectionValidationTest do
  use ExUnit.Case

  alias ScratchBird.Connection

  test "rejects sslmode=disable" do
    assert {:error, "TLS is required for ScratchBird connections"} =
             Connection.connect(
               url: "scratchbird://user:pass@localhost:3092/testdb?sslmode=disable"
             )
  end

  test "rejects binary_transfer=false" do
    assert {:error, "binary_transfer=false is not supported"} =
             Connection.connect(
               url: "scratchbird://user:pass@localhost:3092/testdb?binary_transfer=false"
             )
  end

  test "rejects compression=zstd" do
    assert {:error, "compression=zstd is not supported"} =
             Connection.connect(
               url: "scratchbird://user:pass@localhost:3092/testdb?compression=zstd"
             )
  end
end
