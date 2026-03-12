# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdEctoAdapterTest do
  use ExUnit.Case

  import Ecto.Query

  defmodule ExampleSchema do
    use Ecto.Schema

    @primary_key {:id, :id, []}
    schema "example_records" do
      field :name, :string
    end
  end

  test "prepare all generates executable SQL" do
    query =
      from record in ExampleSchema,
        where: record.name == ^"alpha",
        select: record.name,
        limit: 1

    {planned_query, _cast_params, _dump_params} =
      Ecto.Adapter.Queryable.plan_query(:all, ScratchBird.Ecto, query)

    assert {:cache, {_cache_key, sql}} = ScratchBird.Ecto.prepare(:all, planned_query)
    assert sql =~ "SELECT"
    assert sql =~ "FROM \"example_records\" AS"
    assert sql =~ "WHERE"
    assert sql =~ "$1"
  end

  test "prepare update_all generates executable SQL" do
    query =
      from(record in ExampleSchema,
        where: record.id == ^1,
        update: [set: [name: "beta"]]
      )

    {planned_query, _cast_params, _dump_params} =
      Ecto.Adapter.Queryable.plan_query(:update_all, ScratchBird.Ecto, query)

    assert {:cache, {_cache_key, sql}} = ScratchBird.Ecto.prepare(:update_all, planned_query)
    assert sql =~ "UPDATE \"example_records\" AS"
    assert sql =~ "SET"
    assert sql =~ "WHERE"
  end

  test "prepare delete_all generates executable SQL" do
    query =
      from(record in ExampleSchema,
        where: record.id == ^1
      )

    {planned_query, _cast_params, _dump_params} =
      Ecto.Adapter.Queryable.plan_query(:delete_all, ScratchBird.Ecto, query)

    assert {:cache, {_cache_key, sql}} = ScratchBird.Ecto.prepare(:delete_all, planned_query)
    assert sql =~ "DELETE FROM \"example_records\" AS"
    assert sql =~ "WHERE"
  end

  test "connection schema builders remain available" do
    insert_sql =
      ScratchBird.Ecto.Connection.insert(nil, "example_records", [:name], [["gamma"]], {:raise, [], []}, [], [])
      |> IO.iodata_to_binary()

    update_sql =
      ScratchBird.Ecto.Connection.update(nil, "example_records", [:name], [id: 1], [])
      |> IO.iodata_to_binary()

    delete_sql =
      ScratchBird.Ecto.Connection.delete(nil, "example_records", [id: 1], [])
      |> IO.iodata_to_binary()

    assert insert_sql =~ "INSERT INTO \"example_records\""
    assert update_sql =~ "UPDATE \"example_records\""
    assert delete_sql =~ "DELETE FROM \"example_records\""
  end
end
