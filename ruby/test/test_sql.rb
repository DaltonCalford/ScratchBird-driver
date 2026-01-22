require "test_helper"

class TestSql < Minitest::Test
  def test_substitute_positional
    sql = "SELECT * FROM t WHERE id = ? AND name = ?"
    out = Scratchbird::Sql.substitute(sql, [42, "Ada"])
    assert_equal "SELECT * FROM t WHERE id = 42 AND name = 'Ada'", out
  end

  def test_substitute_named
    sql = "SELECT * FROM users WHERE name = @name AND active = :active"
    out = Scratchbird::Sql.substitute(sql, { name: "Ada", active: true })
    assert_equal "SELECT * FROM users WHERE name = 'Ada' AND active = TRUE", out
  end

  def test_substitute_binary
    sql = "SELECT ?"
    out = Scratchbird::Sql.substitute(sql, ["\x01\x02".b])
    assert_equal "SELECT X'0102'", out
  end
end
