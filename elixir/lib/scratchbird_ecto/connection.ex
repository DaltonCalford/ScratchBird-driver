# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Ecto.Connection do
  @behaviour DBConnection

  alias ScratchBird.Connection

  defstruct [:conn, :config]

  @impl true
  def connect(opts) do
    case Connection.connect(opts) do
      {:ok, conn} -> {:ok, %__MODULE__{conn: conn, config: opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def disconnect(_err, state) do
    _ = Connection.close(state.conn)
    :ok
  end

  @impl true
  def checkout(state), do: {:ok, state}

  @impl true
  def checkin(state), do: {:ok, state}

  @impl true
  def ping(state), do: {:ok, state}

  @impl true
  def handle_begin(_opts, state), do: handle_execute(%DBConnection.Query{statement: "BEGIN"}, [], [], state)

  @impl true
  def handle_commit(_opts, state), do: handle_execute(%DBConnection.Query{statement: "COMMIT"}, [], [], state)

  @impl true
  def handle_rollback(_opts, state), do: handle_execute(%DBConnection.Query{statement: "ROLLBACK"}, [], [], state)

  @impl true
  def handle_prepare(%DBConnection.Query{} = query, _opts, state) do
    {:ok, query, state}
  end

  @impl true
  def handle_execute(%DBConnection.Query{} = query, params, _opts, state) do
    sql = query.statement
    case Connection.query(state.conn, sql, params) do
      {:ok, result, conn} ->
        {:ok, to_db_result(result), %{state | conn: conn}}

      {:error, reason, conn} ->
        {:error, to_db_error(reason), %{state | conn: conn}}
    end
  end

  @impl true
  def handle_close(_query, _opts, state), do: {:ok, nil, state}

  @impl true
  def handle_status(_opts, state), do: {:idle, state}

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp to_db_result(result) do
    %DBConnection.Result{
      columns: Enum.map(result.columns || [], fn col -> col.name end),
      rows: result.rows || [],
      num_rows: length(result.rows || [])
    }
  end

  defp to_db_error(reason) do
    message =
      case reason do
        %{message: msg} -> msg
        _ -> "ScratchBird query failed"
      end

    %DBConnection.Error{message: message}
  end
end
