using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdConnectionStringBuilder : DbConnectionStringBuilder
{
    public string Host
    {
        get => GetString("Host", "localhost");
        set => this["Host"] = value;
    }

    public int Port
    {
        get => GetInt("Port", 3092);
        set => this["Port"] = value;
    }

    public string Database
    {
        get => GetString("Database", string.Empty);
        set => this["Database"] = value;
    }

    public string Username
    {
        get => GetString("Username", string.Empty);
        set => this["Username"] = value;
    }

    public string Password
    {
        get => GetString("Password", string.Empty);
        set => this["Password"] = value;
    }

    public string Schema
    {
        get => GetString("Schema", string.Empty);
        set => this["Schema"] = value;
    }

    public string SSLMode
    {
        get => GetString("SSLMode", "require");
        set => this["SSLMode"] = value;
    }

    public int Timeout
    {
        get => GetInt("Timeout", 30);
        set => this["Timeout"] = value;
    }

    public int CommandTimeout
    {
        get => GetInt("CommandTimeout", 30);
        set => this["CommandTimeout"] = value;
    }

    public bool Pooling
    {
        get => GetBool("Pooling", true);
        set => this["Pooling"] = value;
    }

    public int MinPoolSize
    {
        get => GetInt("MinPoolSize", 0);
        set => this["MinPoolSize"] = value;
    }

    public int MaxPoolSize
    {
        get => GetInt("MaxPoolSize", 100);
        set => this["MaxPoolSize"] = value;
    }

    public int ConnectionLifetime
    {
        get => GetInt("ConnectionLifetime", 0);
        set => this["ConnectionLifetime"] = value;
    }

    public bool Enlist
    {
        get => GetBool("Enlist", true);
        set => this["Enlist"] = value;
    }

    public override string ToString()
    {
        return ConnectionString;
    }

    private string GetString(string key, string fallback)
    {
        return TryGetValue(key, out var value) ? Convert.ToString(value) ?? fallback : fallback;
    }

    private int GetInt(string key, int fallback)
    {
        if (TryGetValue(key, out var value))
        {
            if (value is int i)
            {
                return i;
            }
            if (int.TryParse(Convert.ToString(value), out var parsed))
            {
                return parsed;
            }
        }
        return fallback;
    }

    private bool GetBool(string key, bool fallback)
    {
        if (TryGetValue(key, out var value))
        {
            if (value is bool b)
            {
                return b;
            }
            if (bool.TryParse(Convert.ToString(value), out var parsed))
            {
                return parsed;
            }
        }
        return fallback;
    }
}
