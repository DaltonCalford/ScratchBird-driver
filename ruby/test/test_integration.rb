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
end
