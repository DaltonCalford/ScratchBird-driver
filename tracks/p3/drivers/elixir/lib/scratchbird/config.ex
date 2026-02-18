# ScratchBird-driver
# Copyright (c) 2025-2026 Dalton Calford
#
# Licensed under the Initial Developer's Public License Version 1.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
# https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

defmodule ScratchBird.Config do
  @default_port 3092

  def from_opts(opts) when is_list(opts) do
    opts = Enum.into(opts, %{})
    from_map(opts)
  end

  def from_map(opts) when is_map(opts) do
    base =
      opts
      |> Map.get(:url) || Map.get(opts, :dsn) || Map.get(opts, "url") || Map.get(opts, "dsn")
      |> parse_dsn()

    merged = Map.merge(base, normalize_keys(opts))
    merged
    |> Map.put_new(:port, @default_port)
    |> Map.put_new(:protocol, "native")
    |> Map.put_new(:sslmode, "require")
    |> Map.put_new(:binary_transfer, true)
  end

  def parse_dsn(nil), do: %{}

  def parse_dsn("") do
    %{}
  end

  def parse_dsn(dsn) when is_binary(dsn) do
    if String.contains?(dsn, "://") do
      parse_uri(dsn)
    else
      parse_kv(dsn)
    end
  end

  defp parse_uri(dsn) do
    uri = URI.parse(dsn)
    query = URI.decode_query(uri.query || "")

    %{}
    |> maybe_put(:host, uri.host)
    |> maybe_put(:port, uri.port)
    |> maybe_put(:user, uri.userinfo && uri.userinfo |> String.split(":") |> List.first())
    |> maybe_put(:password, uri.userinfo && uri.userinfo |> String.split(":") |> List.last())
    |> maybe_put(:database, uri.path && String.trim_leading(uri.path, "/"))
    |> Map.merge(normalize_keys(query))
  end

  defp parse_kv(dsn) do
    dsn
    |> String.split(~r/\s+/, trim: true)
    |> Enum.reduce(%{}, fn part, acc ->
      case String.split(part, "=", parts: 2) do
        [key, value] -> Map.put(acc, String.to_atom(key), value)
        _ -> acc
      end
    end)
  end

  defp normalize_keys(opts) do
    opts
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      atom_key =
        key
        |> to_string()
        |> String.downcase()
        |> normalize_alias()
        |> String.to_atom()

      Map.put(acc, atom_key, value)
    end)
  end

  defp normalize_alias("dbname"), do: "database"
  defp normalize_alias("username"), do: "user"
  defp normalize_alias("applicationname"), do: "application_name"
  defp normalize_alias("searchpath"), do: "search_path"
  defp normalize_alias("binarytransfer"), do: "binary_transfer"
  defp normalize_alias("parser"), do: "protocol"
  defp normalize_alias("dialect"), do: "protocol"
  defp normalize_alias("sslrootcert"), do: "sslrootcert"
  defp normalize_alias("sslcert"), do: "sslcert"
  defp normalize_alias("sslkey"), do: "sslkey"
  defp normalize_alias("sslpassword"), do: "sslpassword"
  defp normalize_alias("connecttimeout"), do: "connect_timeout"
  defp normalize_alias("sockettimeout"), do: "socket_timeout"
  defp normalize_alias(name), do: name

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
