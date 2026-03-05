# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBirdErrorsTest do
  use ExUnit.Case

  alias ScratchBird.Errors

  test "maps SQLSTATE classes by prefix" do
    assert Errors.sqlstate_class("01000") == :warning
    assert Errors.sqlstate_class("22P02") == :data_exception
    assert Errors.sqlstate_class("23505") == :integrity_constraint_violation
    assert Errors.sqlstate_class("28000") == :invalid_authorization
    assert Errors.sqlstate_class("40P01") == :transaction_rollback
    assert Errors.sqlstate_class("42P01") == :syntax_error_or_access_rule_violation
    assert Errors.sqlstate_class("53300") == :insufficient_resources
    assert Errors.sqlstate_class("XX000") == :internal_error
  end

  test "falls back to generic class for unknown or malformed codes" do
    assert Errors.sqlstate_class("ZZ999") == :generic
    assert Errors.sqlstate_class("X") == :generic
    assert Errors.sqlstate_class(nil) == :generic
  end
end
