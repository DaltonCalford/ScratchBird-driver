# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Ecto do
  use Ecto.Adapters.SQL, driver: ScratchBird.Ecto.Connection

  @impl true
  def supports_ddl_transaction?, do: true

  @impl true
  def supports_ddl? do
    true
  end

  @impl true
  def dumpers(_primitive, type), do: Ecto.Type.dumpers(type, :binary_id)

  @impl true
  def loaders(_primitive, type), do: Ecto.Type.loaders(type, :binary_id)
end
