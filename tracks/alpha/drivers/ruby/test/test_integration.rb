# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestIntegration < Minitest::Test
  def test_select
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.query("SELECT 1")
      assert_equal 1, result.first[0]
    ensure
      conn.close
    end
  end

  def test_prepare_bind
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.query("SELECT ?::INTEGER", [42])
      assert_equal 42, result.first[0]
    ensure
      conn.close
    end
  end

  def test_types_fixture
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.query("SELECT * FROM type_coverage")
      refute result.rows.empty?
    ensure
      conn.close
    end
  end

  def test_cancel
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn
    cancel_sql = integration_cancel_sql
    skip "SCRATCHBIRD_RUBY_CANCEL_SQL/SCRATCHBIRD_TEST_CANCEL_SQL not set" unless cancel_sql

    conn = Scratchbird.connect(dsn)
    error = nil
    thread = Thread.new do
      begin
        conn.query(cancel_sql)
      rescue StandardError => e
        error = e
      end
    end
    sleep 0.2
    conn.client.cancel
    thread.join(5)
    conn.close
    refute_nil error
  end

  def test_query_multi
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result_sets = conn.query_multi("SELECT 1 AS first_value; SELECT 2 AS second_value")
      assert_equal 2, result_sets.length
      assert_equal 1, result_sets[0].rows.first[0]
      assert_equal 2, result_sets[1].rows.first[0]
    rescue Scratchbird::NotSupportedError, Scratchbird::SyntaxError => e
      skip("query_multi not supported by runtime: #{e.message}") if feature_not_supported?(e)
      raise
    ensure
      conn.close
    end
  end

  def test_execute_batch
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      batch = conn.execute_batch("SELECT ?::INTEGER AS value", [[11], [22], [33]])
      assert_equal 3, batch.items.length
      assert_equal [0, 1, 2], batch.items.map(&:index)
      assert_operator batch.total_rowcount, :>=, 0
    rescue Scratchbird::NotSupportedError, Scratchbird::SyntaxError => e
      skip("execute_batch not supported by runtime: #{e.message}") if feature_not_supported?(e)
      raise
    ensure
      conn.close
    end
  end

  def test_call_callable_escape_syntax
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      result = conn.call("{ ? = call abs(?) }", [-3])
      refute_nil result.first
      assert_equal 3, result.first[0].to_i.abs
    rescue Scratchbird::NotSupportedError, Scratchbird::SyntaxError => e
      skip("call not supported by runtime: #{e.message}") if feature_not_supported?(e)
      raise
    ensure
      conn.close
    end
  end

  def test_execute_with_generated_keys
    dsn = integration_dsn
    skip "SCRATCHBIRD_RUBY_URL/SCRATCHBIRD_TEST_DSN not set" unless dsn

    conn = Scratchbird.connect(dsn)
    begin
      keys = conn.execute_with_generated_keys("SELECT 1")
      assert keys.is_a?(Array)
      assert keys.all? { |id| id.is_a?(Integer) && id >= 0 }
    rescue Scratchbird::NotSupportedError, Scratchbird::SyntaxError => e
      skip("execute_with_generated_keys not supported by runtime: #{e.message}") if feature_not_supported?(e)
      raise
    ensure
      conn.close
    end
  end

  private

  def integration_dsn
    ENV["SCRATCHBIRD_RUBY_URL"] || ENV["SCRATCHBIRD_TEST_DSN"]
  end

  def integration_cancel_sql
    ENV["SCRATCHBIRD_RUBY_CANCEL_SQL"] || ENV["SCRATCHBIRD_TEST_CANCEL_SQL"]
  end

  def feature_not_supported?(error)
    state = error.respond_to?(:sqlstate) ? error.sqlstate.to_s : ""
    state == "0A000"
  end
end
