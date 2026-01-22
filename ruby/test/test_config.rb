require "test_helper"

class TestConfig < Minitest::Test
  def test_parse_uri
    cfg = Scratchbird::Config.parse(
      "scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd"
    )
    assert_equal "localhost", cfg.host
    assert_equal 3092, cfg.port
    assert_equal "mydb", cfg.database
    assert_equal "user", cfg.user
    assert_equal "pass", cfg.password
    assert_equal "require", cfg.sslmode
    assert_equal 3000, cfg.connect_timeout_ms
    assert_equal "app", cfg.application_name
    assert_equal false, cfg.binary_transfer
    assert_equal "zstd", cfg.compression
  end

  def test_parse_key_value
    cfg = Scratchbird::Config.parse(
      "Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7"
    )
    assert_equal "server", cfg.host
    assert_equal 4000, cfg.port
    assert_equal "db", cfg.database
    assert_equal "me", cfg.user
    assert_equal "secret", cfg.password
    assert_equal 5000, cfg.connect_timeout_ms
    assert_equal 7000, cfg.socket_timeout_ms
  end
end
