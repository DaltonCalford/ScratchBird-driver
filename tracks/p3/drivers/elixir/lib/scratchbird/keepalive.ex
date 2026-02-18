# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Keepalive do
  @moduledoc false

  defmodule Config do
    defstruct interval_ms: 120_000,
              max_idle_before_check_ms: 600_000,
              validation_timeout_ms: 5_000
  end

  defmodule Tracker do
    defstruct last_activity_ms: System.monotonic_time(:millisecond),
              config: %Config{}

    def mark_active(%__MODULE__{} = tracker) do
      %{tracker | last_activity_ms: System.monotonic_time(:millisecond)}
    end

    def needs_validation?(%__MODULE__{} = tracker) do
      System.monotonic_time(:millisecond) - tracker.last_activity_ms >
        tracker.config.max_idle_before_check_ms
    end
  end

  def new_tracker(config \\ %Config{}) do
    %Tracker{config: config}
  end
end
