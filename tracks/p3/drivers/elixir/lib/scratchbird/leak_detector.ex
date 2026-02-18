# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.LeakDetector do
  @moduledoc false

  defmodule Config do
    defstruct threshold_ms: 30_000, capture_stack_trace: false
  end

  defmodule Guard do
    defstruct checkout_time_ms: System.monotonic_time(:millisecond),
              config: %Config{},
              metadata: %{},
              stack_trace: nil

    def held_duration_ms(%__MODULE__{} = guard) do
      System.monotonic_time(:millisecond) - guard.checkout_time_ms
    end
  end

  def checkout(config \\ %Config{}, metadata \\ %{}) do
    stack = if config.capture_stack_trace, do: Process.info(self(), :current_stacktrace), else: nil
    %Guard{config: config, metadata: metadata, stack_trace: stack}
  end

  def release(%Guard{} = guard) do
    if held_duration_ms(guard) > guard.config.threshold_ms do
      IO.puts("POSSIBLE CONNECTION LEAK: held=#{held_duration_ms(guard)}ms metadata=#{inspect(guard.metadata)}")
    end
    :ok
  end

  defp held_duration_ms(%Guard{} = guard) do
    Guard.held_duration_ms(guard)
  end
end
