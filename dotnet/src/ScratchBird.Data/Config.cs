using System.Globalization;

namespace ScratchBird.Data;

public sealed class ScratchBirdConfig
{
    public string Host { get; set; } = "localhost";
    public int Port { get; set; } = 3092;
    public string Database { get; set; } = "";
    public string Username { get; set; } = "";
    public string Password { get; set; } = "";
    public string SslMode { get; set; } = "prefer";
    public string? SslRootCert { get; set; }
    public string? SslCert { get; set; }
    public string? SslKey { get; set; }
    public int ConnectTimeoutMs { get; set; } = 30000;
    public int SocketTimeoutMs { get; set; } = 0;
    public string ApplicationName { get; set; } = "scratchbird_dotnet";
    public bool BinaryTransfer { get; set; } = true;
    public string Compression { get; set; } = "off";

    public static ScratchBirdConfig FromConnectionString(string connectionString)
    {
        var parsed = DsnParser.Parse(connectionString);
        return parsed;
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
            case "database":
            case "dbname":
            case "initial catalog":
                cfg.Database = value;
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
            case "sslmode":
            case "ssl mode":
                cfg.SslMode = value;
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
        }
    }
}
