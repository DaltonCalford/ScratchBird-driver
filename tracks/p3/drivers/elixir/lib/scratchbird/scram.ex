# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Scram do
  @moduledoc false

  defstruct [:username, :client_nonce, :client_first_bare, :server_signature]

  def new(username) do
    nonce = :crypto.strong_rand_bytes(18) |> Base.encode64()
    %__MODULE__{username: username, client_nonce: nonce}
  end

  def client_first(%__MODULE__{username: username, client_nonce: nonce} = state) do
    bare = "n=#{escape(username)},r=#{nonce}"
    {"n,," <> bare, %{state | client_first_bare: bare}}
  end

  def handle_server_first(%__MODULE__{} = state, password, server_first) do
    attrs = parse_attrs(server_first)
    nonce = Map.get(attrs, "r", "")
    salt = Map.get(attrs, "s", "")
    iter = Map.get(attrs, "i", "0")

    if nonce == "" or not String.starts_with?(nonce, state.client_nonce) do
      {:error, "SCRAM server nonce mismatch"}
    else
      iterations = String.to_integer(iter)
      salt_bin = Base.decode64!(salt)
      salted = pbkdf2_sha256(password, salt_bin, iterations, 32)
      client_key = hmac_sha256(salted, "Client Key")
      stored_key = :crypto.hash(:sha256, client_key)
      client_final = "c=biws,r=" <> nonce
      auth_message = state.client_first_bare <> "," <> server_first <> "," <> client_final
      client_sig = hmac_sha256(stored_key, auth_message)
      client_proof = xor_bytes(client_key, client_sig)
      server_key = hmac_sha256(salted, "Server Key")
      server_sig = hmac_sha256(server_key, auth_message)
      response = client_final <> ",p=" <> Base.encode64(client_proof)
      {:ok, response, %{state | server_signature: server_sig}}
    end
  end

  def verify_server_final(%__MODULE__{server_signature: sig}, server_final) do
    attrs = parse_attrs(server_final)
    verifier = Map.get(attrs, "v")
    expected = Base.encode64(sig || <<>>)
    if verifier == expected, do: :ok, else: {:error, "SCRAM server signature mismatch"}
  end

  defp escape(text) do
    text
    |> String.replace("=", "=3D")
    |> String.replace(",", "=2C")
  end

  defp parse_attrs(message) do
    message
    |> String.split(",", trim: true)
    |> Enum.reduce(%{}, fn part, acc ->
      case String.split(part, "=", parts: 2) do
        [k, v] -> Map.put(acc, k, v)
        _ -> acc
      end
    end)
  end

  defp hmac_sha256(key, data) when is_binary(data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end

  defp hmac_sha256(key, data) when is_list(data) do
    :crypto.mac(:hmac, :sha256, key, to_string(data))
  end

  defp xor_bytes(left, right) do
    left
    |> :binary.bin_to_list()
    |> Enum.zip(:binary.bin_to_list(right))
    |> Enum.map(fn {l, r} -> Bitwise.bxor(l, r) end)
    |> :binary.list_to_bin()
  end

  defp pbkdf2_sha256(password, salt, iterations, key_len) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, iterations, key_len)
  end
end
