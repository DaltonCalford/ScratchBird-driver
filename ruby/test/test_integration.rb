require "test_helper"

class TestIntegration < Minitest::Test
  def test_select
    dsn = ENV["SCRATCHBIRD_RUBY_URL"]
    skip "SCRATCHBIRD_RUBY_URL not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.query("SELECT 1")
      assert_equal 1, result.first[0]
    ensure
      conn.close
    end
  end

  def test_prepare_bind
    dsn = ENV["SCRATCHBIRD_RUBY_URL"]
    skip "SCRATCHBIRD_RUBY_URL not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.query("SELECT ?::INTEGER", [42])
      assert_equal 42, result.first[0]
    ensure
      conn.close
    end
  end

  def test_types_fixture
    dsn = ENV["SCRATCHBIRD_RUBY_URL"]
    skip "SCRATCHBIRD_RUBY_URL not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.query("SELECT * FROM sb_conformance.type_coverage")
      refute result.rows.empty?
    ensure
      conn.close
    end
  end
end
