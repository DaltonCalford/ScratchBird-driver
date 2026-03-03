# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"

class TestConnAuthProtocol < Minitest::Test
  FakeSocket = Struct.new(:close_calls) do
    def close
      self.close_calls += 1
    end
  end

  def test_connect_requires_user_and_database
    cfg = base_config
    cfg.user = ""
    cfg.database = ""
    client = Scratchbird::Client.new(cfg)

    err = assert_raises(Scratchbird::ConnectionError) { client.connect }
    assert_equal "user and database are required", err.message
  end

  def test_connect_rejects_binary_transfer_false
    cfg = base_config
    cfg.binary_transfer = false
    client = Scratchbird::Client.new(cfg)

    err = assert_raises(Scratchbird::NotSupportedError) { client.connect }
    assert_equal "binary_transfer=false is not supported", err.message
  end

  def test_connect_rejects_zstd_compression
    cfg = base_config
    cfg.compression = "zstd"
    client = Scratchbird::Client.new(cfg)

    err = assert_raises(Scratchbird::NotSupportedError) { client.connect }
    assert_equal "compression=zstd is not supported", err.message
  end

  def test_connect_rejects_non_native_protocol
    cfg = base_config
    cfg.protocol = "postgresql"
    client = Scratchbird::Client.new(cfg)

    err = assert_raises(Scratchbird::NotSupportedError) { client.connect }
    assert_match(/Only protocol=native is supported/, err.message)
  end

  def test_connect_rejects_invalid_front_door_mode
    cfg = base_config
    cfg.front_door_mode = "invalid"
    client = Scratchbird::Client.new(cfg)

    err = assert_raises(Scratchbird::NotSupportedError) { client.connect }
    assert_equal "front_door_mode must be direct or manager_proxy.", err.message
  end

  def test_wrap_tls_rejects_sslmode_disable
    cfg = base_config
    cfg.sslmode = "disable"
    client = Scratchbird::Client.new(cfg)

    err = assert_raises(Scratchbird::ConnectionError) { client.send(:wrap_tls, FakeSocket.new(0)) }
    assert_equal "TLS is required for ScratchBird connections", err.message
  end

  def test_connect_closes_socket_when_manager_proxy_auth_token_missing
    cfg = base_config
    cfg.front_door_mode = "manager_proxy"
    cfg.manager_auth_token = ""
    client = Scratchbird::Client.new(cfg)
    fake_socket = FakeSocket.new(0)

    client.define_singleton_method(:connect_tcp) { fake_socket }
    client.define_singleton_method(:wrap_tls) { |raw_socket| raw_socket }

    err = assert_raises(Scratchbird::ConnectionError) { client.connect }
    assert_equal "manager_proxy mode requires manager_auth_token", err.message
    assert_equal 1, fake_socket.close_calls
    assert_equal false, client.connected?
  end

  def test_manager_proxy_auth_failure_raises_auth_error
    cfg = base_config
    cfg.front_door_mode = "manager_proxy"
    cfg.manager_auth_token = "bad-token"
    client = Scratchbird::Client.new(cfg)
    sent = []
    responses = [
      [Scratchbird::Client::MCP_MSG_STATUS_RESPONSE, "".b],
      [Scratchbird::Client::MCP_MSG_AUTH_RESPONSE, manager_auth_error_payload("bad token")]
    ]

    client.define_singleton_method(:send_manager_frame) do |type, payload|
      sent << [type, payload]
    end
    client.define_singleton_method(:recv_manager_frame) do
      frame = responses.shift
      raise "missing fake manager frame" unless frame
      frame
    end

    err = assert_raises(Scratchbird::AuthError) { client.send(:perform_manager_connect) }
    assert_equal "bad token", err.message
    assert_equal(
      [Scratchbird::Client::MCP_MSG_HELLO, Scratchbird::Client::MCP_MSG_AUTH_START],
      sent.map(&:first)
    )
  end

  def test_protocol_parse_auth_continue_round_trip
    payload = [Scratchbird::Protocol::AUTH_SCRAM_SHA256, 2, 0, 0].pack("C4")
    payload << [5].pack("V")
    payload << "nonce"

    method, stage, data = Scratchbird::Protocol.parse_auth_continue(payload)
    assert_equal Scratchbird::Protocol::AUTH_SCRAM_SHA256, method
    assert_equal 2, stage
    assert_equal "nonce", data
  end

  def test_protocol_parse_auth_continue_rejects_truncated_payload
    payload = [Scratchbird::Protocol::AUTH_SCRAM_SHA256, 1, 0, 0].pack("C4")
    payload << [8].pack("V")
    payload << "tiny"

    err = assert_raises(RuntimeError) { Scratchbird::Protocol.parse_auth_continue(payload) }
    assert_equal "Auth continue truncated", err.message
  end

  private

  def base_config
    cfg = Scratchbird::Config.new
    cfg.user = "test_user"
    cfg.database = "test_db"
    cfg
  end

  def manager_auth_error_payload(message)
    [1].pack("C") + [0].pack("V") + message.to_s.b.ljust(256, "\0")
  end
end
