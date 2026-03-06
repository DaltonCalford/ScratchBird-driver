# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
require "test_helper"
require "base64"
require "openssl"

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

  def test_connect_allows_binary_transfer_false
    cfg = base_config
    cfg.binary_transfer = false
    client = Scratchbird::Client.new(cfg)
    client.define_singleton_method(:connect_tcp) { raise "tcp_invoked" }

    err = assert_raises(RuntimeError) { client.connect }
    assert_equal "tcp_invoked", err.message
  end

  def test_connect_allows_zstd_compression
    cfg = base_config
    cfg.compression = "zstd"
    client = Scratchbird::Client.new(cfg)
    client.define_singleton_method(:connect_tcp) { raise "tcp_invoked" }

    err = assert_raises(RuntimeError) { client.connect }
    assert_equal "tcp_invoked", err.message
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

  def test_manager_proxy_connect_success
    cfg = base_config
    cfg.front_door_mode = "manager_proxy"
    cfg.manager_auth_token = "token"
    client = Scratchbird::Client.new(cfg)
    sent = []
    responses = [
      [Scratchbird::Client::MCP_MSG_STATUS_RESPONSE, "".b],
      [Scratchbird::Client::MCP_MSG_AUTH_RESPONSE, manager_auth_success_payload],
      [Scratchbird::Client::MCP_MSG_CONNECT_RESPONSE, manager_connect_success_payload]
    ]

    client.define_singleton_method(:send_manager_frame) do |type, payload|
      sent << [type, payload]
    end
    client.define_singleton_method(:recv_manager_frame) do
      frame = responses.shift
      raise "missing fake manager frame" unless frame
      frame
    end

    assert_nil client.send(:perform_manager_connect)
    assert_equal(
      [
        Scratchbird::Client::MCP_MSG_HELLO,
        Scratchbird::Client::MCP_MSG_AUTH_START,
        Scratchbird::Client::MCP_MSG_DB_CONNECT
      ],
      sent.map(&:first)
    )
  end

  def test_handshake_scram_success_with_server_verifier
    cfg = base_config
    cfg.password = "secret-password"
    client = Scratchbird::Client.new(cfg)
    attachment = ("a" * 16).b
    sent = []
    step = 0
    client_first = nil
    client_final = nil
    server_first = nil
    auth_request_payload = build_auth_request_payload(Scratchbird::Protocol::AUTH_SCRAM_SHA256)
    auth_continue_builder = method(:build_auth_continue_payload)
    auth_ok_builder = method(:build_auth_ok_payload)
    verifier_builder = method(:compute_scram_server_verifier)
    ready_payload = build_ready_payload(0, 77)

    client.define_singleton_method(:send_message) do |type, payload, _flags, _force_zero|
      sent << [type, payload]
      if type == Scratchbird::Protocol::MSG_AUTH_RESPONSE
        if client_first.nil?
          client_first = payload
        else
          client_final = payload
        end
      end
      sent.length
    end

    client.define_singleton_method(:recv_message) do
      step += 1
      case step
      when 1
        [Scratchbird::Protocol::MSG_AUTH_REQUEST, 0, auth_request_payload, 0, attachment, 0]
      when 2
        nonce = client_first.to_s.split("r=", 2).last
        salt = Base64.strict_encode64("testsalt")
        server_first = "r=#{nonce}server,s=#{salt},i=4096"
        [Scratchbird::Protocol::MSG_AUTH_CONTINUE, 0, auth_continue_builder.call(server_first), 0, attachment, 0]
      when 3
        verifier = verifier_builder.call(
          password: cfg.password,
          client_first: client_first,
          server_first: server_first,
          client_final: client_final
        )
        [Scratchbird::Protocol::MSG_AUTH_OK, 0, auth_ok_builder.call("v=#{verifier}"), 0, attachment, 77]
      when 4
        [Scratchbird::Protocol::MSG_READY, 0, ready_payload, 0, attachment, 77]
      else
        raise "unexpected recv step #{step}"
      end
    end

    client.send(:handshake)
    assert_equal 77, client.txn_id
    assert_equal attachment, client.instance_variable_get(:@attachment_id)
    assert_equal Scratchbird::Protocol::MSG_STARTUP, sent[0][0]
    assert_equal Scratchbird::Protocol::MSG_AUTH_RESPONSE, sent[1][0]
    assert_equal Scratchbird::Protocol::MSG_AUTH_RESPONSE, sent[2][0]
  end

  def test_handshake_scram_rejects_bad_server_verifier
    cfg = base_config
    cfg.password = "secret-password"
    client = Scratchbird::Client.new(cfg)
    attachment = ("b" * 16).b
    step = 0
    client_first = nil
    server_first = nil
    auth_request_payload = build_auth_request_payload(Scratchbird::Protocol::AUTH_SCRAM_SHA256)
    auth_continue_builder = method(:build_auth_continue_payload)
    auth_ok_builder = method(:build_auth_ok_payload)

    client.define_singleton_method(:send_message) do |type, payload, _flags, _force_zero|
      if type == Scratchbird::Protocol::MSG_AUTH_RESPONSE && client_first.nil?
        client_first = payload
      end
      true
    end

    client.define_singleton_method(:recv_message) do
      step += 1
      case step
      when 1
        [Scratchbird::Protocol::MSG_AUTH_REQUEST, 0, auth_request_payload, 0, attachment, 0]
      when 2
        nonce = client_first.to_s.split("r=", 2).last
        salt = Base64.strict_encode64("testsalt")
        server_first = "r=#{nonce}server,s=#{salt},i=4096"
        [Scratchbird::Protocol::MSG_AUTH_CONTINUE, 0, auth_continue_builder.call(server_first), 0, attachment, 0]
      when 3
        [Scratchbird::Protocol::MSG_AUTH_OK, 0, auth_ok_builder.call("v=invalid-signature"), 0, attachment, 1]
      else
        raise "unexpected recv step #{step}"
      end
    end

    err = assert_raises(RuntimeError) { client.send(:handshake) }
    assert_equal "SCRAM server signature mismatch", err.message
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

  def manager_auth_success_payload
    [0].pack("C") + [0].pack("V") + ("\0" * 256)
  end

  def manager_connect_success_payload
    "\0".b + ("\0" * (1 + 2 + 2 + 16 + 64 + 32 - 1))
  end

  def build_auth_request_payload(method)
    [method, 0, 0, 0].pack("C4")
  end

  def build_auth_continue_payload(data)
    [Scratchbird::Protocol::AUTH_SCRAM_SHA256, 1, 0, 0].pack("C4") + [data.bytesize].pack("V") + data
  end

  def build_auth_ok_payload(server_info)
    session_id = ("s" * 16).b
    session_id + [server_info.bytesize].pack("V") + server_info
  end

  def build_ready_payload(status, txn_id)
    [status].pack("C") + "\0\0\0" + [txn_id, 0].pack("Q<Q<")
  end

  def compute_scram_server_verifier(password:, client_first:, server_first:, client_final:)
    client_first_bare = client_first.to_s.sub(/\An,,/, "")
    client_final_without_proof = client_final.to_s.split(",p=", 2).first
    salt_b64 = server_first.split(",").find { |part| part.start_with?("s=") }.to_s.sub(/\As=/, "")
    iterations = server_first.split(",").find { |part| part.start_with?("i=") }.to_s.sub(/\Ai=/, "").to_i
    salt = Base64.decode64(salt_b64)
    salted = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, 32, "sha256")
    server_key = OpenSSL::HMAC.digest("sha256", salted, "Server Key")
    auth_message = "#{client_first_bare},#{server_first},#{client_final_without_proof}"
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", server_key, auth_message))
  end
end
