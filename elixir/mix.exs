# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdEcto.MixProject do
  use Mix.Project

  def project do
    [
      app: :scratchbird_ecto,
      version: "0.1.0",
      elixir: "~> 1.15",
      deps: deps(),
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto, :ssl]]
  end

  defp deps do
    [
      {:db_connection, "~> 2.6"},
      {:ecto_sql, "~> 3.11"},
      {:decimal, "~> 2.0"}
    ]
  end
end
