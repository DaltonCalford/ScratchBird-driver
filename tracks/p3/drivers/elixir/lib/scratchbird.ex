# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird do
  @moduledoc false

  alias ScratchBird.{Errors, Metadata, Protocol}

  defdelegate schemas_query(), to: Metadata
  defdelegate tables_query(), to: Metadata
  defdelegate columns_query(), to: Metadata
  defdelegate indexes_query(), to: Metadata
  defdelegate index_columns_query(), to: Metadata
  defdelegate constraints_query(), to: Metadata
  defdelegate procedures_query(), to: Metadata
  defdelegate functions_query(), to: Metadata

  defdelegate sqlstate_class(code), to: Errors
  defdelegate retry_scope(code), to: Errors
  defdelegate retryable?(code), to: Errors
  defdelegate canonical_read_committed_mode_label(mode), to: Protocol
  defdelegate supports_prepared_transactions(), to: ScratchBird.Connection
  defdelegate supports_dormant_reattach(), to: ScratchBird.Connection
  defdelegate supports_portal_resume(), to: ScratchBird.Connection
end
