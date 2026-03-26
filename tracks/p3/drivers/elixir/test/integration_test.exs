# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdIntegrationTest do
  use ExUnit.Case

  alias ScratchBird.Connection

  setup do
    dsn = System.get_env("SCRATCHBIRD_TEST_DSN")

    if is_binary(dsn) and String.trim(dsn) != "" do
      {:ok, dsn: dsn}
    else
      {:skip, "SCRATCHBIRD_TEST_DSN not set"}
    end
  end

  test "connect and basic query", %{dsn: dsn} do
    {:ok, conn} = Connection.connect(url: dsn)

    try do
      {:ok, result, _conn} = Connection.query(conn, "SELECT 1", [])
      assert length(result.rows) > 0
      assert length(List.first(result.rows)) > 0
      assert List.first(List.first(result.rows)) == 1
    after
      Connection.close(conn)
    end
  end

  test "parameterized query", %{dsn: dsn} do
    {:ok, conn} = Connection.connect(url: dsn)

    try do
      {:ok, result, _conn} = Connection.query(conn, "SELECT ?::INTEGER", [42])
      assert length(result.rows) > 0
      assert length(List.first(result.rows)) > 0
      assert List.first(List.first(result.rows)) == 42
    after
      Connection.close(conn)
    end
  end

  test "rollback leaves immediate query usable on native fresh boundary", %{dsn: dsn} do
    {:ok, conn} = Connection.connect(url: dsn)

    try do
      {:ok, conn} = Connection.begin(conn)

      {:ok, _result, conn} =
        Connection.query(
          conn,
          "UPDATE basic_table SET name = 'elixir-rollback-probe' WHERE name = 'baseline'",
          []
        )

      {:ok, conn} = Connection.rollback(conn)

      {:ok, baseline_result, conn} =
        Connection.query(conn, "SELECT 1 FROM basic_table WHERE name = 'baseline'", [])

      assert length(baseline_result.rows) == 1
      assert length(List.first(baseline_result.rows)) == 1
      refute is_nil(List.first(List.first(baseline_result.rows)))

      {:ok, probe_result, _conn} =
        Connection.query(
          conn,
          "SELECT 1 FROM basic_table WHERE name = 'elixir-rollback-probe'",
          []
        )

      assert probe_result.rows == []
    after
      Connection.close(conn)
    end
  end
end

defmodule ScratchBirdManagerProxyIntegrationTest do
  use ExUnit.Case

  alias ScratchBird.Connection

  setup do
    dsn = System.get_env("SCRATCHBIRD_TEST_MANAGER_DSN")

    if is_binary(dsn) and String.trim(dsn) != "" do
      {:ok, dsn: dsn}
    else
      {:skip, "SCRATCHBIRD_TEST_MANAGER_DSN not set"}
    end
  end

  test "manager-proxy connect and basic query", %{dsn: dsn} do
    {:ok, conn} = Connection.connect(url: dsn)

    try do
      assert conn.config[:front_door_mode] == "manager_proxy"
      {:ok, result, _conn} = Connection.query(conn, "SELECT 1", [])
      assert length(result.rows) > 0
      assert length(List.first(result.rows)) > 0
      assert List.first(List.first(result.rows)) == 1
    after
      Connection.close(conn)
    end
  end
end
