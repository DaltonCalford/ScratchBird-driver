// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Globalization;

namespace ScratchBird.Data;

public sealed class ScratchBirdConfig
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 3092;
    public string FrontDoorMode { get; set; } = "direct";
    public string Protocol { get; set; } = "native";
    public string Database { get; set; } = "";
    public string Username { get; set; } = "";
    public string Password { get; set; } = "";
    public string Schema { get; set; } = "";
    public bool MetadataExpandSchemaParents { get; set; } = false;
    public string Role { get; set; } = "";
    public string SslMode { get; set; } = "require";
    public bool AllowInsecureDisable { get; set; } = false;
    public string? SslRootCert { get; set; }
    public string? SslCert { get; set; }
    public string? SslKey { get; set; }
    public string? SslPassword { get; set; }
    public int ConnectTimeoutMs { get; set; } = 30000;
    public int SocketTimeoutMs { get; set; } = 0;
    public string ApplicationName { get; set; } = "scratchbird_dotnet";
    public bool BinaryTransfer { get; set; } = true;
    public string Compression { get; set; } = "off";
    public int DefaultFetchSize { get; set; } = 0;
    public bool Pooling { get; set; } = false;
    public int MinPoolSize { get; set; } = 0;
    public int MaxPoolSize { get; set; } = 100;
    public int ConnectionLifetime { get; set; } = 0;
    public string ManagerAuthToken { get; set; } = string.Empty;
    public string ManagerUsername { get; set; } = string.Empty;
    public string ManagerDatabase { get; set; } = string.Empty;
    public string ManagerConnectionProfile { get; set; } = "native_v3";
    public string ManagerClientIntent { get; set; } = "native_v3";
    public ushort ManagerClientFlags { get; set; } = 0;
    public bool ManagerAuthFastPath { get; set; } = true;

    public static ScratchBirdConfig FromConnectionString(string connectionString)
    {
        var parsed = DsnParser.Parse(connectionString);
        return parsed;
    }

    internal static string NormalizeNativeProtocol(string? value)
    {
        var normalized = (value ?? string.Empty).Trim().ToLowerInvariant();
        return normalized switch
        {
            "" or "native" or "scratchbird" or "scratchbird-native" or "scratchbird_native" => "native",
            _ => throw new ArgumentException("Only protocol=native is supported; connect to the native parser listener/port.")
        };
    }

    internal static string NormalizeFrontDoorMode(string? value)
    {
        var normalized = (value ?? string.Empty).Trim().ToLowerInvariant();
        return normalized switch
        {
            "" or "direct" => "direct",
            "manager_proxy" or "manager-proxy" or "managed" => "manager_proxy",
            _ => throw new ArgumentException("front_door_mode must be direct or manager_proxy.")
        };
    }
}

internal static class DsnParser
{
    public static ScratchBirdConfig Parse(string dsn)
    {
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return new ScratchBirdConfig();
        }

        if (dsn.Contains("://", StringComparison.Ordinal))
        {
            return ParseUri(dsn);
        }

        return ParseKeyValue(dsn);
    }

    private static ScratchBirdConfig ParseUri(string dsn)
    {
        var uri = new Uri(dsn);
        if (!string.Equals(uri.Scheme, "scratchbird", StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException($"Unsupported DSN scheme: {uri.Scheme}");
        }

        var cfg = new ScratchBirdConfig();
        if (!string.IsNullOrEmpty(uri.Host)) cfg.Host = uri.Host;
        if (uri.Port > 0) cfg.Port = uri.Port;
        if (!string.IsNullOrEmpty(uri.UserInfo))
        {
            var parts = uri.UserInfo.Split(':', 2);
            cfg.Username = Uri.UnescapeDataString(parts[0]);
            if (parts.Length > 1) cfg.Password = Uri.UnescapeDataString(parts[1]);
        }
        if (!string.IsNullOrEmpty(uri.AbsolutePath) && uri.AbsolutePath != "/")
        {
            cfg.Database = uri.AbsolutePath.TrimStart('/');
        }

        var query = uri.Query.TrimStart('?');
        if (!string.IsNullOrEmpty(query))
        {
            foreach (var pair in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
            {
                var idx = pair.IndexOf('=');
                if (idx <= 0) continue;
                var key = pair[..idx];
                var value = Uri.UnescapeDataString(pair[(idx + 1)..]);
                ApplyParam(cfg, key, value);
            }
        }

        return cfg;
    }

    private static ScratchBirdConfig ParseKeyValue(string dsn)
    {
        var cfg = new ScratchBirdConfig();
        var tokens = SplitConnectionString(dsn);
        foreach (var token in tokens)
        {
            var idx = token.IndexOf('=');
            if (idx <= 0) continue;
            var key = token[..idx].Trim();
            var value = token[(idx + 1)..].Trim().Trim('"');
            ApplyParam(cfg, key, value);
        }
        return cfg;
    }

    private static IEnumerable<string> SplitConnectionString(string dsn)
    {
        var separator = dsn.Contains(';') ? ';' : ' ';
        return dsn.Split(separator, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
    }

    private static void ApplyParam(ScratchBirdConfig cfg, string key, string value)
    {
        switch (key.ToLowerInvariant())
        {
            case "host":
            case "server":
            case "data source":
            case "datasource":
                cfg.Host = value;
                break;
            case "port":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var port))
                    cfg.Port = port;
                break;
            case "front_door_mode":
            case "frontdoormode":
            case "connection_mode":
            case "ingress_mode":
                cfg.FrontDoorMode = ScratchBirdConfig.NormalizeFrontDoorMode(value);
                break;
            case "database":
            case "dbname":
            case "initial catalog":
                cfg.Database = value;
                break;
            case "protocol":
            case "parser":
            case "dialect":
                cfg.Protocol = ScratchBirdConfig.NormalizeNativeProtocol(value);
                break;
            case "user":
            case "username":
            case "user id":
            case "uid":
                cfg.Username = value;
                break;
            case "password":
            case "pwd":
                cfg.Password = value;
                break;
            case "schema":
            case "search_path":
            case "searchpath":
            case "currentschema":
                cfg.Schema = value;
                break;
            case "metadataexpandschemaparents":
            case "metadata_expand_schema_parents":
            case "expandschemaparents":
            case "expand_schema_parents":
            case "dbeaverexpandschemaparents":
            case "dbeaver_expand_schema_parents":
                cfg.MetadataExpandSchemaParents = value.Equals("true", StringComparison.OrdinalIgnoreCase)
                    || value.Equals("1", StringComparison.Ordinal)
                    || value.Equals("yes", StringComparison.OrdinalIgnoreCase)
                    || value.Equals("on", StringComparison.OrdinalIgnoreCase);
                break;
            case "role":
                cfg.Role = value;
                break;
            case "sslmode":
            case "ssl mode":
                cfg.SslMode = value;
                break;
            case "allow_insecure":
            case "allowinsecure":
            case "allow_insecure_disable":
            case "allowinsecuredisable":
                cfg.AllowInsecureDisable = value.Equals("true", StringComparison.OrdinalIgnoreCase)
                    || value.Equals("1", StringComparison.Ordinal)
                    || value.Equals("yes", StringComparison.OrdinalIgnoreCase)
                    || value.Equals("on", StringComparison.OrdinalIgnoreCase);
                break;
            case "sslrootcert":
                cfg.SslRootCert = value;
                break;
            case "sslcert":
                cfg.SslCert = value;
                break;
            case "sslkey":
                cfg.SslKey = value;
                break;
            case "sslpassword":
                cfg.SslPassword = value;
                break;
            case "connect_timeout":
            case "connecttimeout":
            case "timeout":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var timeout))
                    cfg.ConnectTimeoutMs = timeout * 1000;
                break;
            case "socket_timeout":
            case "sockettimeout":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var sockTimeout))
                    cfg.SocketTimeoutMs = sockTimeout * 1000;
                break;
            case "application_name":
            case "applicationname":
                cfg.ApplicationName = value;
                break;
            case "binary_transfer":
            case "binarytransfer":
                cfg.BinaryTransfer = value.Equals("true", StringComparison.OrdinalIgnoreCase) || value == "1";
                break;
            case "compression":
                cfg.Compression = value.Equals("zstd", StringComparison.OrdinalIgnoreCase) ? "zstd" : "off";
                break;
            case "fetch_size":
            case "fetchsize":
            case "default_fetch_size":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var fetch))
                    cfg.DefaultFetchSize = Math.Max(0, fetch);
                break;
            case "pooling":
                cfg.Pooling = value.Equals("true", StringComparison.OrdinalIgnoreCase) || value == "1";
                break;
            case "minpoolsize":
            case "minimumpoolsize":
            case "min_pool_size":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var minPool))
                    cfg.MinPoolSize = Math.Max(0, minPool);
                break;
            case "maxpoolsize":
            case "maximumpoolsize":
            case "max_pool_size":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var maxPool))
                    cfg.MaxPoolSize = Math.Max(1, maxPool);
                break;
            case "connectionlifetime":
            case "connection_lifetime":
                if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var lifetime))
                    cfg.ConnectionLifetime = Math.Max(0, lifetime);
                break;
            case "manager_auth_token":
            case "mcp_auth_token":
                cfg.ManagerAuthToken = value;
                break;
            case "manager_username":
            case "mcp_username":
                cfg.ManagerUsername = value;
                break;
            case "manager_database":
            case "mcp_database":
                cfg.ManagerDatabase = value;
                break;
            case "manager_connection_profile":
            case "mcp_connection_profile":
                cfg.ManagerConnectionProfile = value;
                break;
            case "manager_client_intent":
            case "mcp_client_intent":
                cfg.ManagerClientIntent = value;
                break;
            case "manager_client_flags":
            case "mcp_client_flags":
                if (ushort.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var managerFlags))
                    cfg.ManagerClientFlags = managerFlags;
                break;
            case "manager_auth_fast_path":
            case "mcp_auth_fast_path":
                cfg.ManagerAuthFastPath = value.Equals("true", StringComparison.OrdinalIgnoreCase)
                    || value.Equals("1", StringComparison.Ordinal)
                    || value.Equals("yes", StringComparison.OrdinalIgnoreCase)
                    || value.Equals("on", StringComparison.OrdinalIgnoreCase);
                break;
        }
    }
}
