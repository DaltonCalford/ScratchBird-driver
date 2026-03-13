# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestSql < Minitest::Test
  def test_normalize_positional
    sql = "SELECT * FROM t WHERE id = ? AND name = ?"
    normalized = Scratchbird::Sql.normalize(sql, [42, "Ada"])
    assert_equal "SELECT * FROM t WHERE id = $1 AND name = $2", normalized.sql
    assert_equal [42, "Ada"], normalized.params
  end

  def test_normalize_named
    sql = "SELECT * FROM users WHERE name = @name AND active = :active"
    normalized = Scratchbird::Sql.normalize(sql, { name: "Ada", active: true })
    assert_equal "SELECT * FROM users WHERE name = $1 AND active = $2", normalized.sql
    assert_equal ["Ada", true], normalized.params
  end

  def test_normalize_binary
    sql = "SELECT ?"
    normalized = Scratchbird::Sql.normalize(sql, ["\x01\x02".b])
    assert_equal "SELECT $1", normalized.sql
    assert_equal ["\x01\x02".b], normalized.params
  end

  def test_normalize_callable_escape_syntax
    normalized = Scratchbird::Sql.normalize_callable("{ ? = call abs(?) }", [-3])
    assert_equal "select abs($1) as return_value", normalized.sql
    assert_equal [-3], normalized.params
  end

  def test_normalize_callable_sql_passthrough
    sql = Scratchbird::Sql.normalize_callable_sql("SELECT 1")
    assert_equal "SELECT 1", sql
  end
end
