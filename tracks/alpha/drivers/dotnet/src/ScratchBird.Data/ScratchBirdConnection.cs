// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Threading;

namespace ScratchBird.Data;

public sealed class ScratchBirdConnection : DbConnection
{
    private const int MaxConnectRetries = 3;
    private const int ReconnectBackoffMs = 120;

    private string _connectionString = string.Empty;
    private ConnectionState _state = ConnectionState.Closed;
    private ScratchBirdConfig _config = new();
    private ProtocolClient? _client;
    private ProtocolClientPool.Lease? _clientLease;

    public ScratchBirdConnection() { }

    public ScratchBirdConnection(string connectionString)
    {
        ConnectionString = connectionString;
    }

    public override string ConnectionString
    {
        get => _connectionString;
        set
        {
            if (_state != ConnectionState.Closed)
            {
                throw new InvalidOperationException("Cannot set ConnectionString while open");
            }
            _connectionString = value;
            _config = ScratchBirdConfig.FromConnectionString(value);
        }
    }

    public override string Database => _config.Database;

    public override string DataSource => _config.Host;

    public override string ServerVersion => "1.0";

    public override ConnectionState State => _state;

    internal ProtocolClient Client => _client ?? throw new InvalidOperationException("Connection not open");
    internal ScratchBirdConfig Config => _config;
    internal ProtocolClient GetConnectedClient() => EnsureConnectedClient();

    public override void Open()
    {
        if (_state != ConnectionState.Closed)
        {
            return;
        }

        OpenWithRetry();
        _state = ConnectionState.Open;
    }

    private void OpenWithRetry()
    {
        ScratchBirdException? lastFailure = null;

        for (var attempt = 0; attempt < MaxConnectRetries; attempt++)
        {
            try
            {
                BorrowAndConnect();
                return;
            }
            catch (ScratchBirdException ex)
            {
                lastFailure = ex;
                _clientLease?.Dispose();
                _clientLease = null;
                _client = null;

                if (attempt + 1 < MaxConnectRetries)
                {
                    Thread.Sleep(Math.Min(ReconnectBackoffMs * (1 << attempt), 1000));
                    continue;
                }

                throw;
            }
        }

        if (lastFailure != null)
        {
            throw lastFailure;
        }
    }

    private void BorrowAndConnect()
    {
        _clientLease?.Dispose();
        _clientLease = null;

        _client = ProtocolClientPool.BorrowOrCreate(_config, out var lease);
        _clientLease = lease;
        try
        {
            _client.Connect(_config);
            _state = ConnectionState.Open;
            ApplySchema();
        }
        catch
        {
            _clientLease?.Dispose();
            _clientLease = null;
            _client = null;
            throw;
        }
    }

    private ProtocolClient EnsureConnectedClient()
    {
        if (_state != ConnectionState.Open)
        {
            throw new InvalidOperationException("Connection is not open");
        }

        if (_client == null)
        {
            OpenWithRetry();
            return _client ?? throw new InvalidOperationException("Connection could not be restored");
        }

        if (_client.IsHealthy)
        {
            return _client;
        }

        _clientLease?.Dispose();
        _clientLease = null;
        _client = null;
        OpenWithRetry();

        return _client ?? throw new InvalidOperationException("Connection could not be restored");
    }

    public override async Task OpenAsync(CancellationToken cancellationToken)
    {
        await Task.Run(Open, cancellationToken);
    }

    public override void Close()
    {
        var lease = _clientLease;
        _clientLease = null;
        _client = null;
        _state = ConnectionState.Closed;
        lease?.Dispose();
    }

    public override void ChangeDatabase(string databaseName)
    {
        if (string.IsNullOrWhiteSpace(databaseName))
        {
            throw new ArgumentException("databaseName is required");
        }
        _config.Database = databaseName;
    }

    protected override DbTransaction BeginDbTransaction(IsolationLevel isolationLevel)
    {
        if (_state != ConnectionState.Open)
        {
            throw new InvalidOperationException("Connection is not open");
        }
        GetConnectedClient().Begin(isolationLevel);
        return new ScratchBirdTransaction(this, isolationLevel);
    }

    protected override DbCommand CreateDbCommand()
    {
        return new ScratchBirdCommand { Connection = this };
    }

    private void ApplySchema()
    {
        if (string.IsNullOrWhiteSpace(_config.Schema) ||
            _config.Schema.Equals("public", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }
        var statement = BuildSchemaStatement(_config.Schema);
        if (string.IsNullOrWhiteSpace(statement) || _client == null)
        {
            return;
        }
        var stream = _client.ExecuteQuery(statement);
        while (stream.ReadNextRow() != null)
        {
        }
    }

    private static string BuildSchemaStatement(string schema)
    {
        var trimmed = schema.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            return string.Empty;
        }
        if (trimmed.Contains(',', StringComparison.Ordinal))
        {
            var parts = trimmed.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(QuoteIdentifier)
                .ToArray();
            if (parts.Length == 0)
            {
                return string.Empty;
            }
            return $"SET SEARCH_PATH TO {string.Join(", ", parts)}";
        }
        return $"SET SCHEMA {QuoteIdentifier(trimmed)}";
    }

    private static string QuoteIdentifier(string name)
    {
        return $"\"{name.Replace("\"", "\"\"")}\"";
    }
}
