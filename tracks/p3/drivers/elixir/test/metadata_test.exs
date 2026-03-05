# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdMetadataTest do
  use ExUnit.Case

  alias ScratchBird

  test "exposes required sys catalog metadata queries" do
    assert String.contains?(ScratchBird.schemas_query(), "FROM sys.schemas")
    assert String.contains?(ScratchBird.tables_query(), "FROM sys.tables")
    assert String.contains?(ScratchBird.columns_query(), "FROM sys.columns")
    assert String.contains?(ScratchBird.indexes_query(), "FROM sys.indexes")
    assert String.contains?(ScratchBird.index_columns_query(), "FROM sys.index_columns")
    assert String.contains?(ScratchBird.constraints_query(), "FROM sys.constraints")
    assert String.contains?(ScratchBird.procedures_query(), "FROM sys.procedures")
    assert String.contains?(ScratchBird.functions_query(), "FROM sys.functions")
  end
end
