# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Connection do
  @moduledoc false

  alias ScratchBird.{Config, Protocol, Scram, Types}
  use Bitwise

  defstruct [
    :socket,
    :transport,
    :config,
    sequence: 0,
    attachment_id: <<0::128>>,
    txn_id: 0,
    params: %{},
    authed: false,
    last_query_sequence: 0,
    notification_handlers: [],
    last_plan: nil,
    last_sblr: nil
  ]

  def connect(opts) do
    config = Config.from_opts(opts)
    with :ok <- validate_config(config),
         {:ok, socket, transport} <- open_socket(config),
         {:ok, state} <- handshake(%__MODULE__{socket: socket, transport: transport, config: config}) do
      {:ok, state}
    end
  end

  def close(%__MODULE__{transport: :ssl, socket: socket}), do: :ssl.close(socket)
  def close(%__MODULE__{transport: :tcp, socket: socket}), do: :gen_tcp.close(socket)

  defp validate_config(config) do
    sslmode = (config[:sslmode] || "require") |> String.downcase()
    cond do
      sslmode == "disable" ->
        {:error, "TLS is required for ScratchBird connections"}
      config[:binary_transfer] == false ->
        {:error, "binary_transfer=false is not supported"}
      config[:compression] == "zstd" ->
        {:error, "compression=zstd is not supported"}
      true ->
        :ok
    end
  end

  def query(state, sql, params) when is_list(params) do
    if params == [] do
      send_simple_query(state, sql)
    else
      send_extended_query(state, sql, params)
    end
  end

  def begin(state, opts \\ %{}) do
    flags = 0
    flags = if Map.has_key?(opts, :isolation_level), do: flags ||| Protocol.txn_flag(:has_isolation), else: flags
    flags = if Map.has_key?(opts, :access_mode), do: flags ||| Protocol.txn_flag(:has_access), else: flags
    flags = if Map.has_key?(opts, :deferrable), do: flags ||| Protocol.txn_flag(:has_deferrable), else: flags
    flags = if Map.has_key?(opts, :wait), do: flags ||| Protocol.txn_flag(:has_wait), else: flags
    flags = if Map.has_key?(opts, :timeout_ms), do: flags ||| Protocol.txn_flag(:has_timeout), else: flags
    flags = if Map.has_key?(opts, :autocommit_mode), do: flags ||| Protocol.txn_flag(:has_autocommit), else: flags
    payload =
      Protocol.build_txn_begin_payload(
        flags,
        Map.get(opts, :conflict_action, 0),
        Map.get(opts, :autocommit_mode, 0),
        Map.get(opts, :isolation_level, Protocol.isolation(:read_committed)),
        Map.get(opts, :access_mode, 0),
        if(Map.get(opts, :deferrable), do: 1, else: 0),
        if(Map.get(opts, :wait), do: 1, else: 0),
        Map.get(opts, :timeout_ms, 0)
      )
    state = send_message(state, Protocol.message_type(:txn_begin), payload, 0)
    drain_until_ready(state)
  end

  def commit(state, flags \\ 0) do
    payload = Protocol.build_txn_commit_payload(flags)
    state = send_message(state, Protocol.message_type(:txn_commit), payload, 0)
    drain_until_ready(state)
  end

  def rollback(state, flags \\ 0) do
    payload = Protocol.build_txn_rollback_payload(flags)
    state = send_message(state, Protocol.message_type(:txn_rollback), payload, 0)
    drain_until_ready(state)
  end

  def savepoint(state, name) do
    payload = Protocol.build_txn_savepoint_payload(name)
    state = send_message(state, Protocol.message_type(:txn_savepoint), payload, 0)
    drain_until_ready(state)
  end

  def release_savepoint(state, name) do
    payload = Protocol.build_txn_release_payload(name)
    state = send_message(state, Protocol.message_type(:txn_release), payload, 0)
    drain_until_ready(state)
  end

  def rollback_to_savepoint(state, name) do
    payload = Protocol.build_txn_rollback_to_payload(name)
    state = send_message(state, Protocol.message_type(:txn_rollback_to), payload, 0)
    drain_until_ready(state)
  end

  def set_option(state, name, value) do
    payload = Protocol.build_set_option_payload(name, value)
    state = send_message(state, Protocol.message_type(:set_option), payload, 0)
    drain_until_ready(state)
  end

  def ping(state) do
    state = send_message(state, Protocol.message_type(:ping), <<>>, 0)
    case recv_message(state) do
      {:ok, msg} ->
        case handle_async(state, msg) do
          {:handled, new_state} -> ping(new_state)
          {:ok, new_state} ->
            case msg.type do
              type when type == Protocol.message_type(:pong) -> {:ok, new_state}
              type when type == Protocol.message_type(:ready) ->
                {:ok, status, txn_id} = Protocol.parse_ready(msg.payload)
                {:ok, %{new_state | txn_id: txn_id}}
              type when type == Protocol.message_type(:error) -> {:error, Protocol.parse_error(msg.payload), new_state}
              _ -> ping(new_state)
            end
        end
      error -> error
    end
  end

  def terminate(state) do
    _ = send_message(state, Protocol.message_type(:terminate), <<>>, 0)
    close(state)
  end

  def subscribe(state, channel, opts \\ %{}) do
    payload = Protocol.build_subscribe_payload(
      Map.get(opts, :subscribe_type, Protocol.subscribe_type(:channel)),
      channel,
      Map.get(opts, :filter_expr, "")
    )
    state = send_message(state, Protocol.message_type(:subscribe), payload, 0)
    drain_until_ready(state)
  end

  def unsubscribe(state, channel) do
    payload = Protocol.build_unsubscribe_payload(channel)
    state = send_message(state, Protocol.message_type(:unsubscribe), payload, 0)
    drain_until_ready(state)
  end

  def execute_sblr(state, sblr_hash, sblr_bytecode, params \\ []) do
    {param_values, _param_types} =
      params
      |> Enum.map(&Types.encode_param/1)
      |> Enum.map(fn {param, oid} -> {param, oid} end)
      |> Enum.unzip()
    payload = Protocol.build_sblr_execute_payload(sblr_hash, sblr_bytecode, param_values)
    state = %{state | last_plan: nil, last_sblr: nil}
    sequence = state.sequence
    state = send_message(state, Protocol.message_type(:sblr_execute), payload, 0)
    state = %{state | last_query_sequence: sequence}
    state = send_message(state, Protocol.message_type(:sync), <<>>, 0)
    collect_results(state, [])
  end

  def stream_control(state, control_type, window_size \\ 0, timeout_ms \\ 0) do
    payload = Protocol.build_stream_control_payload(control_type, window_size, timeout_ms)
    state = send_message(state, Protocol.message_type(:stream_control), payload, 0)
    {:ok, state}
  end

  def attach_create(state, emulation_mode, db_name) do
    payload = Protocol.build_attach_create_payload(emulation_mode, db_name)
    state = send_message(state, Protocol.message_type(:attach_create), payload, 0)
    drain_until_ready(state)
  end

  def attach_detach(state) do
    state = send_message(state, Protocol.message_type(:attach_detach), <<>>, 0)
    drain_until_ready(state)
  end

  def attach_list(state) do
    state = send_message(state, Protocol.message_type(:attach_list), <<>>, 0)
    state = send_message(state, Protocol.message_type(:sync), <<>>, 0)
    collect_results(state, [])
  end

  def cancel(state) do
    payload = Protocol.build_cancel_payload(0, state.last_query_sequence)
    _ = send_message(state, Protocol.message_type(:cancel), payload, Protocol.flag(:urgent))
    {:ok, state}
  end

  def on_notification(state, handler) when is_function(handler, 1) do
    {:ok, %{state | notification_handlers: state.notification_handlers ++ [handler]}}
  end

  def last_query_plan(state), do: state.last_plan
  def last_sblr_compiled(state), do: state.last_sblr

  defp open_socket(config) do
    host = to_charlist(config[:host] || "localhost")
    port = config[:port] || 3092
    sslmode = (config[:sslmode] || "require") |> String.downcase()

    opts = [
      mode: :binary,
      packet: :raw,
      active: false
    ]

    if sslmode == "disable" do
      {:error, "TLS is required for ScratchBird connections"}
    else
      ssl_opts = [
        verify: :verify_none,
        versions: [:'tlsv1.3']
      ]

      case :ssl.connect(host, port, ssl_opts ++ opts, 5000) do
        {:ok, socket} -> {:ok, socket, :ssl}
        err -> err
      end
    end
  end

  defp handshake(state) do
    features = requested_features(state.config)
    params = %{
      "database" => state.config[:database] || "",
      "user" => state.config[:user] || ""
    }
    params = if state.config[:role], do: Map.put(params, "role", state.config[:role]), else: params
    params = if state.config[:application_name], do: Map.put(params, "application_name", state.config[:application_name]), else: params

    payload = Protocol.build_startup_payload(features, params)
    state = send_message(state, Protocol.message_type(:startup), payload, 0)

    loop_auth(state, nil)
  end

  defp loop_auth(state, scram) do
    with {:ok, msg} <- recv_message(state) do
      case msg.type do
        type when type == Protocol.message_type(:negotiate_version) ->
          loop_auth(state, scram)

        type when type == Protocol.message_type(:auth_request) ->
          {:ok, method, data} = Protocol.parse_auth_request(msg.payload)
          {state, scram} = handle_auth_request(state, method, data, scram)
          loop_auth(state, scram)

        type when type == Protocol.message_type(:auth_continue) ->
          {:ok, method, _stage, data} = Protocol.parse_auth_continue(msg.payload)
          {state, scram} = handle_auth_continue(state, method, data, scram)
          loop_auth(state, scram)

        type when type == Protocol.message_type(:auth_ok) ->
        {:ok, _session_id, info} = Protocol.parse_auth_ok(msg.payload)
        state = %{state | attachment_id: msg.attachment_id, txn_id: msg.txn_id, authed: true}
        if scram && byte_size(info) > 0 do
          _ = Scram.verify_server_final(scram, to_string(info))
        end
        loop_auth(state, scram)

        type when type == Protocol.message_type(:parameter_status) ->
          {:ok, name, value} = Protocol.parse_parameter_status(msg.payload)
          loop_auth(%{state | params: Map.put(state.params, name, value)}, scram)

        type when type == Protocol.message_type(:ready) ->
          {:ok, _status, txn_id} = Protocol.parse_ready(msg.payload)
          state = %{state | txn_id: txn_id}
          state = apply_search_path(state)
          {:ok, state}

        type when type == Protocol.message_type(:error) ->
          {:error, Protocol.parse_error(msg.payload)}

        _ ->
          loop_auth(state, scram)
      end
    end
  end

  defp handle_auth_request(state, method, data, scram) do
    case method do
      0 -> {state, scram}
      1 ->
        password = state.config[:password] || ""
        {send_message(state, Protocol.message_type(:auth_response), password, 0), scram}

      3 ->
        scram = scram || Scram.new(state.config[:user] || "")
        {client_first, scram} = Scram.client_first(scram)
        {send_message(state, Protocol.message_type(:auth_response), client_first, 0), scram}

      _ ->
        raise "Unsupported auth method"
    end
  end

  defp handle_auth_continue(state, method, data, scram) do
    case method do
      3 ->
        password = state.config[:password] || ""
        {:ok, client_final, scram} = Scram.handle_server_first(scram, password, data)
        {send_message(state, Protocol.message_type(:auth_response), client_final, 0), scram}

      _ ->
        {state, scram}
    end
  end

  defp send_simple_query(state, sql) do
    flags = if state.config[:binary_transfer], do: Protocol.query_flag(:binary_result), else: 0
    payload = Protocol.build_query_payload(sql, flags, 0, 0)
    state = %{state | last_plan: nil, last_sblr: nil}
    sequence = state.sequence
    state = send_message(state, Protocol.message_type(:query), payload, 0)
    state = %{state | last_query_sequence: sequence}
    collect_results(state, [])
  end

  defp apply_search_path(state) do
    schema = state.config[:search_path] || state.config[:schema]
    if is_binary(schema) and String.trim(schema) != "" and String.downcase(schema) != "public" do
      case send_simple_query(state, "SET SEARCH_PATH TO " <> schema) do
        {:ok, _result, new_state} -> new_state
        {:error, _reason, new_state} -> new_state
      end
    else
      state
    end
  end

  defp send_extended_query(state, sql, params) do
    {param_values, param_types} =
      params
      |> Enum.map(&Types.encode_param/1)
      |> Enum.map(fn {param, oid} -> {param, oid} end)
      |> Enum.unzip()

    state = send_message(state, Protocol.message_type(:parse), Protocol.build_parse_payload("", sql, param_types), 0)
    case describe_statement(state) do
      {:ok, _count, state} ->
        state = send_message(state, Protocol.message_type(:bind), Protocol.build_bind_payload("", "", param_values, [1]), 0)
        state = %{state | last_plan: nil, last_sblr: nil}
        sequence = state.sequence
        state = send_message(state, Protocol.message_type(:execute), Protocol.build_execute_payload("", 0), 0)
        state = %{state | last_query_sequence: sequence}
        state = send_message(state, Protocol.message_type(:sync), <<>>, 0)
        collect_results(state, [])

      {:error, reason, state} ->
        {:error, reason, state}
    end
  end

  defp describe_statement(state) do
    state = send_message(state, Protocol.message_type(:describe), Protocol.build_describe_payload(?S, ""), 0)
    state = send_message(state, Protocol.message_type(:sync), <<>>, 0)
    describe_loop(state, -1)
  end

  defp describe_loop(state, param_count) do
    case recv_message(state) do
      {:ok, msg} ->
        case handle_async(state, msg) do
          {:handled, new_state} -> describe_loop(new_state, param_count)
          {:ok, new_state} ->
            case msg.type do
              type when type == Protocol.message_type(:parameter_description) ->
                count = length(Protocol.parse_parameter_description(msg.payload))
                describe_loop(new_state, count)
              type when type == Protocol.message_type(:ready) ->
                {:ok, _status, txn_id} = Protocol.parse_ready(msg.payload)
                {:ok, param_count, %{new_state | txn_id: txn_id}}
              type when type == Protocol.message_type(:error) ->
                {:error, Protocol.parse_error(msg.payload), new_state}
              _ ->
                describe_loop(new_state, param_count)
            end
        end
      error -> error
    end
  end

  defp handle_async(state, msg) do
    case msg.type do
      type when type == Protocol.message_type(:parameter_status) ->
        {:ok, name, value} = Protocol.parse_parameter_status(msg.payload)
        new_state = update_parameter_status(state, to_string(name), to_string(value))
        {:handled, new_state}

      type when type == Protocol.message_type(:notification) ->
        notice = Protocol.parse_notification(msg.payload)
        Enum.each(state.notification_handlers, fn handler -> handler.(notice) end)
        {:handled, state}

      type when type == Protocol.message_type(:query_plan) ->
        plan = Protocol.parse_query_plan(msg.payload)
        {:handled, %{state | last_plan: plan}}

      type when type == Protocol.message_type(:sblr_compiled) ->
        compiled = Protocol.parse_sblr_compiled(msg.payload)
        {:handled, %{state | last_sblr: compiled}}

      _ ->
        {:ok, state}
    end
  end

  defp update_parameter_status(state, name, value) do
    state = %{state | params: Map.put(state.params, name, value)}
    state =
      if name == "attachment_id" do
        case parse_uuid_bytes(value) do
          {:ok, bytes} -> %{state | attachment_id: bytes}
          _ -> state
        end
      else
        state
      end
    if name == "current_txn_id" do
      case Integer.parse(value) do
        {txn_id, _} -> %{state | txn_id: txn_id}
        _ -> state
      end
    else
      state
    end
  end

  defp parse_uuid_bytes(value) do
    hex =
      value
      |> String.replace("-", "")
      |> String.trim()
    if String.match?(hex, ~r/^[0-9A-Fa-f]{32}$/) do
      Base.decode16(hex, case: :mixed)
    else
      :error
    end
  end

  defp drain_until_ready(state) do
    case recv_message(state) do
      {:ok, msg} ->
        case handle_async(state, msg) do
          {:handled, new_state} -> drain_until_ready(new_state)
          {:ok, new_state} ->
            case msg.type do
              type when type == Protocol.message_type(:ready) ->
                {:ok, _status, txn_id} = Protocol.parse_ready(msg.payload)
                {:ok, %{new_state | txn_id: txn_id}}
              type when type == Protocol.message_type(:error) ->
                {:error, Protocol.parse_error(msg.payload), new_state}
              _ ->
                drain_until_ready(new_state)
            end
        end
      error -> error
    end
  end

  defp collect_results(state, rows) do
    case recv_message(state) do
      {:ok, msg} ->
        case handle_async(state, msg) do
          {:handled, new_state} -> collect_results(new_state, rows)
          {:ok, new_state} ->
            case msg.type do
              type when type == Protocol.message_type(:row_description) ->
                columns = Protocol.parse_row_description(msg.payload)
                collect_rows(new_state, columns, rows)

              type when type == Protocol.message_type(:data_row) ->
                {values, _} = Protocol.parse_data_row(msg.payload)
                collect_results(new_state, [values | rows])

              type when type == Protocol.message_type(:command_complete) ->
                collect_results(new_state, rows)

              type when type == Protocol.message_type(:ready) ->
                {:ok, _status, txn_id} = Protocol.parse_ready(msg.payload)
                {:ok, %{rows: Enum.reverse(rows), columns: []}, %{new_state | txn_id: txn_id}}

              type when type == Protocol.message_type(:error) ->
                {:error, Protocol.parse_error(msg.payload), new_state}

              _ ->
                collect_results(new_state, rows)
            end
        end
      error -> error
    end
  end

  defp collect_rows(state, columns, rows) do
    case recv_message(state) do
      {:ok, msg} ->
        case handle_async(state, msg) do
          {:handled, new_state} -> collect_rows(new_state, columns, rows)
          {:ok, new_state} ->
            case msg.type do
              type when type == Protocol.message_type(:data_row) ->
                {values, _} = Protocol.parse_data_row(msg.payload)
                decoded = decode_row(columns, values)
                collect_rows(new_state, columns, [decoded | rows])

              type when type == Protocol.message_type(:command_complete) ->
                collect_rows(new_state, columns, rows)

              type when type == Protocol.message_type(:ready) ->
                {:ok, _status, txn_id} = Protocol.parse_ready(msg.payload)
                {:ok, %{rows: Enum.reverse(rows), columns: columns}, %{new_state | txn_id: txn_id}}

              type when type == Protocol.message_type(:error) ->
                {:error, Protocol.parse_error(msg.payload), new_state}

              _ ->
                collect_rows(new_state, columns, rows)
            end
        end

      error -> error
    end
  end

  defp decode_row(columns, values) do
    Enum.zip(columns, values)
    |> Enum.map(fn {col, val} ->
      if val.null do
        nil
      else
        Types.decode_value(col.type_oid, val.data, col.format)
      end
    end)
  end

  defp requested_features(config) do
    features = 0
    features = if config[:compression] == "zstd", do: features ||| Protocol.feature(:compression), else: features
    features = if config[:binary_transfer], do: features ||| Protocol.feature(:streaming), else: features
    features
  end

  defp send_message(state, type, payload, flags) do
    header = %{
      type: type,
      flags: flags,
      length: byte_size(payload),
      sequence: state.sequence,
      attachment_id: state.attachment_id,
      txn_id: state.txn_id
    }
    data = Protocol.encode_message(header, payload)
    _ = case state.transport do
      :ssl -> :ssl.send(state.socket, data)
      :tcp -> :gen_tcp.send(state.socket, data)
    end
    %{state | sequence: state.sequence + 1}
  end

  defp recv_message(state) do
    with {:ok, header_bin} <- recv_exact(state, Protocol.header_size()),
         {:ok, header} <- Protocol.decode_header(header_bin),
         {:ok, payload} <- recv_exact(state, header.length) do
      {:ok, Map.put(header, :payload, payload)}
    end
  end

  defp recv_exact(_state, 0), do: {:ok, <<>>}

  defp recv_exact(state, bytes) do
    case state.transport do
      :ssl -> :ssl.recv(state.socket, bytes)
      :tcp -> :gen_tcp.recv(state.socket, bytes)
    end
  end
end
