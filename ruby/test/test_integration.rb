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
      result = conn.query("SELECT * FROM type_coverage")
      refute result.rows.empty?
    ensure
      conn.close
    end
  end

  def test_cancel
    dsn = ENV["SCRATCHBIRD_RUBY_URL"]
    skip "SCRATCHBIRD_RUBY_URL not set" unless dsn
    cancel_sql = ENV["SCRATCHBIRD_RUBY_CANCEL_SQL"]
    skip "SCRATCHBIRD_RUBY_CANCEL_SQL not set" unless cancel_sql

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
end
