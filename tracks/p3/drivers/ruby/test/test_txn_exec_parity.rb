# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestTxnExecParity < Minitest::Test
  class FakeClient
    attr_reader :calls

    def initialize
      @calls = []
      @in_transaction = false
    end

    def in_transaction?
      @in_transaction
    end

    def begin_transaction
      @calls << :begin_transaction
      @in_transaction = true
      true
    end

    def commit
      @calls << :commit
      @in_transaction = false
      true
    end

    def rollback
      @calls << :rollback
      @in_transaction = false
      true
    end

    def savepoint(name)
      @calls << [:savepoint, name]
      true
    end

    def rollback_to_savepoint(name)
      @calls << [:rollback_to_savepoint, name]
      true
    end

    def release_savepoint(name)
      @calls << [:release_savepoint, name]
      true
    end

    def query(sql, params = nil, options = nil)
      @calls << [:query, sql, params, options]
      :query_result
    end

    def stream(sql, params = nil, options = nil)
      @calls << [:stream, sql, params, options]
      :stream_result
    end

    def prepare(name, sql)
      @calls << [:prepare, name, sql]
      true
    end

    def execute(name, params = nil, options = nil)
      @calls << [:execute, name, params, options]
      :execute_result
    end

    def execute_stream(name, params = nil, options = nil)
      @calls << [:execute_stream, name, params, options]
      :execute_stream_result
    end

    def deallocate(name)
      @calls << [:deallocate, name]
      true
    end

    def native_sql(sql, params = nil)
      @calls << [:native_sql, sql, params]
      "native_sql_result"
    end

    def native_callable_sql(sql, params = nil)
      @calls << [:native_callable_sql, sql, params]
      "native_callable_sql_result"
    end

    def call(sql, params = nil, options = nil)
      @calls << [:call, sql, params, options]
      :call_result
    end

    def query_multi(sql, params = nil, options = nil)
      @calls << [:query_multi, sql, params, options]
      [:query_multi_result]
    end

    def execute_batch(sql, batch_params, options = nil)
      @calls << [:execute_batch, sql, batch_params, options]
      :execute_batch_result
    end

    def execute_with_generated_keys(sql, params = nil, options = nil)
      @calls << [:execute_with_generated_keys, sql, params, options]
      [101]
    end
  end

  def test_execute_starts_transaction_once_when_autocommit_disabled
    client = FakeClient.new
    conn = build_connection(client, autocommit: false)

    first = conn.execute("SELECT 1")
    second = conn.execute("SELECT 2")

    assert_equal :query_result, first
    assert_equal :query_result, second
    assert_equal 1, client.calls.count(:begin_transaction)
  end

  def test_commit_and_rollback_reset_transaction_gate
    client = FakeClient.new
    conn = build_connection(client, autocommit: false)

    conn.execute("SELECT 1")
    conn.commit
    conn.execute("SELECT 2")
    conn.rollback
    conn.execute("SELECT 3")

    assert_equal 3, client.calls.count(:begin_transaction)
    assert_equal 1, client.calls.count(:commit)
    assert_equal 1, client.calls.count(:rollback)
  end

  def test_query_and_stream_forward_options
    client = FakeClient.new
    conn = build_connection(client)

    conn.query("SELECT $1", [7], max_rows: 2)
    conn.stream("SELECT $1", [8], timeout_ms: 50)

    assert_includes client.calls, [:query, "SELECT $1", [7], { max_rows: 2 }]
    assert_includes client.calls, [:stream, "SELECT $1", [8], { timeout_ms: 50 }]
    assert_equal 0, client.calls.count(:begin_transaction)
  end

  def test_statement_execute_and_stream_use_connection_transaction_gate
    client = FakeClient.new
    conn = build_connection(client, autocommit: false)
    stmt = Scratchbird::Statement.new(conn, "SELECT ?")

    result = stmt.execute([1], max_rows: 1)
    stream = stmt.stream([2], timeout_ms: 10)

    assert_equal :execute_result, result
    assert_equal :execute_stream_result, stream
    assert_equal 1, client.calls.count(:begin_transaction)
    assert_includes client.calls, [:execute, stmt.instance_variable_get(:@name), [1], { max_rows: 1 }]
    assert_includes client.calls, [:execute_stream, stmt.instance_variable_get(:@name), [2], { timeout_ms: 10 }]
  end

  def test_statement_execute_raises_when_closed
    client = FakeClient.new
    conn = build_connection(client)
    stmt = Scratchbird::Statement.new(conn, "SELECT 1")
    stmt.close

    err = assert_raises(Scratchbird::Error) { stmt.execute }
    assert_equal "statement is closed", err.message
  end

  def test_connection_savepoint_api_forwards_to_client
    client = FakeClient.new
    conn = build_connection(client)

    conn.savepoint("sp1")
    conn.rollback_to_savepoint("sp1")
    conn.release_savepoint("sp1")

    assert_includes client.calls, [:savepoint, "sp1"]
    assert_includes client.calls, [:rollback_to_savepoint, "sp1"]
    assert_includes client.calls, [:release_savepoint, "sp1"]
  end

  def test_statement_close_deallocates_prepared_handle
    client = FakeClient.new
    conn = build_connection(client)
    stmt = Scratchbird::Statement.new(conn, "SELECT 1")
    name = stmt.instance_variable_get(:@name)

    stmt.close

    assert stmt.closed?
    assert_includes client.calls, [:deallocate, name]
  end

  def test_native_sql_and_native_callable_sql_forward_to_client
    client = FakeClient.new
    conn = build_connection(client)

    native = conn.native_sql("SELECT ?::INTEGER", [1])
    callable = conn.native_callable_sql("{ ? = call abs(?) }", [-1])

    assert_equal "native_sql_result", native
    assert_equal "native_callable_sql_result", callable
    assert_includes client.calls, [:native_sql, "SELECT ?::INTEGER", [1]]
    assert_includes client.calls, [:native_callable_sql, "{ ? = call abs(?) }", [-1]]
  end

  def test_exec_parity_surfaces_use_transaction_gate_and_forward
    client = FakeClient.new
    conn = build_connection(client, autocommit: false)

    call_result = conn.call("{ ? = call abs(?) }", [-3], max_rows: 1)
    query_multi_result = conn.query_multi("SELECT 1; SELECT 2")
    batch_result = conn.execute_batch("SELECT ?::INTEGER", [[11], [22]])
    generated = conn.execute_with_generated_keys("SELECT 1")

    assert_equal :call_result, call_result
    assert_equal [:query_multi_result], query_multi_result
    assert_equal :execute_batch_result, batch_result
    assert_equal [101], generated
    assert_equal 1, client.calls.count(:begin_transaction)
    assert_includes client.calls, [:call, "{ ? = call abs(?) }", [-3], { max_rows: 1 }]
    assert_includes client.calls, [:query_multi, "SELECT 1; SELECT 2", nil, nil]
    assert_includes client.calls, [:execute_batch, "SELECT ?::INTEGER", [[11], [22]], nil]
    assert_includes client.calls, [:execute_with_generated_keys, "SELECT 1", nil, nil]
  end

  private

  def build_connection(client, autocommit: true)
    conn = Scratchbird::Connection.allocate
    conn.instance_variable_set(:@client, client)
    conn.instance_variable_set(:@autocommit, autocommit)
    conn.instance_variable_set(:@closed, false)
    conn.instance_variable_set(:@config, Scratchbird::Config.new)
    conn
  end
end
