# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestResultStream < Minitest::Test
  class FakeStreamClient
    attr_reader :updated_txn_ids

    def initialize(messages)
      @messages = messages
      @updated_txn_ids = []
    end

    def recv_message
      raise "no queued messages" if @messages.empty?

      @messages.shift
    end

    def handle_query_error(_payload)
      raise Scratchbird::Error, "query failed"
    end

    def decode_row(_columns, values)
      values
    end

    def update_txn_id(txn_id)
      @updated_txn_ids << txn_id
    end

    def send(method_name, *args, &block)
      return false if method_name == :handle_async_message

      super
    end
  end

  def test_result_supports_each_hash_and_generated_key
    result = Scratchbird::Result.new(
      [{ name: "id", type_oid: 23, type_modifier: -1, format: 1, nullable: true }],
      [[10], [11]],
      2,
      "INSERT 0 2",
      901
    )

    assert_equal ["id"], result.fields
    assert_equal 2, result.rowcount
    assert_equal "INSERT 0 2", result.command_tag
    assert_equal 901, result.last_insert_id
    assert_equal [{"id" => 10}, {"id" => 11}], result.each_hash.to_a
  end

  def test_stream_each_hash_tracks_command_summary
    client = FakeStreamClient.new(
      [
        message(Scratchbird::Protocol::MSG_ROW_DESCRIPTION, :row_desc_payload),
        message(Scratchbird::Protocol::MSG_DATA_ROW, [1, "ada"]),
        message(Scratchbird::Protocol::MSG_DATA_ROW, [2, "linus"]),
        message(Scratchbird::Protocol::MSG_COMMAND_COMPLETE, :command_payload),
        message(Scratchbird::Protocol::MSG_READY, :ready_payload)
      ]
    )

    with_protocol_parse_stubs(
      parse_row_description: ->(_payload) { [{ name: "id" }, { name: "name" }] },
      parse_data_row: ->(payload) { payload },
      parse_command_complete: ->(_payload) { ["SELECT", 2, 77, "SELECT 2"] },
      parse_ready: ->(_payload) { [0, 42] }
    ) do
      stream = Scratchbird::ResultStream.new(client)
      rows = stream.each_hash.to_a

      assert_equal [{"id" => 1, "name" => "ada"}, {"id" => 2, "name" => "linus"}], rows
      assert_equal 2, stream.rowcount
      assert_equal "SELECT 2", stream.command_tag
      assert_equal 77, stream.last_insert_id
      assert_equal [42], client.updated_txn_ids
    end
  end

  def test_stream_rejects_second_consumption
    client = FakeStreamClient.new(
      [
        message(Scratchbird::Protocol::MSG_READY, :ready_payload)
      ]
    )

    with_protocol_parse_stubs(parse_ready: ->(_payload) { [0, 0] }) do
      stream = Scratchbird::ResultStream.new(client)
      assert_equal [], stream.each.to_a

      err = assert_raises(Scratchbird::Error) { stream.each.to_a }
      assert_equal "stream already consumed", err.message
    end
  end

  private

  def message(type, payload)
    [type, 0, payload, 1, ("\0" * 16), 0]
  end

  def with_protocol_parse_stubs(stubs)
    singleton = Scratchbird::Protocol.singleton_class
    originals = {}
    stubs.each do |name, proc|
      originals[name] = Scratchbird::Protocol.method(name)
      singleton.send(:define_method, name, &proc)
    end
    yield
  ensure
    originals.each do |name, original|
      singleton.send(:define_method, name, original)
    end
  end
end
