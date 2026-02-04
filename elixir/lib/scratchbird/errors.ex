# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Errors do
  @moduledoc false

  def sqlstate_class(code) when is_binary(code) and byte_size(code) >= 2 do
    case binary_part(code, 0, 2) do
      "01" -> :warning
      "02" -> :no_data
      "08" -> :connection_exception
      "0A" -> :feature_not_supported
      "22" -> :data_exception
      "23" -> :integrity_constraint_violation
      "28" -> :invalid_authorization
      "40" -> :transaction_rollback
      "42" -> :syntax_error_or_access_rule_violation
      "53" -> :insufficient_resources
      "54" -> :program_limit_exceeded
      "57" -> :operator_intervention
      "58" -> :system_error
      "XX" -> :internal_error
      _ -> :generic
    end
  end

  def sqlstate_class(_), do: :generic
end
