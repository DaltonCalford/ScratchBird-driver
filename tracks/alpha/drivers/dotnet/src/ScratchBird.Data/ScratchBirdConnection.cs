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

namespace ScratchBird.Data;

public sealed class ScratchBirdConnection : DbConnection
{
    private string _connectionString = string.Empty;
    private ConnectionState _state = ConnectionState.Closed;
    private ScratchBirdConfig _config = new();
    private ProtocolClient? _client;

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

    public override void Open()
    {
        if (_state != ConnectionState.Closed)
        {
            return;
        }
        _client = new ProtocolClient();
        _client.Connect(_config);
        ApplySchema();
        _state = ConnectionState.Open;
    }

    public override async Task OpenAsync(CancellationToken cancellationToken)
    {
        await Task.Run(Open, cancellationToken);
    }

    public override void Close()
    {
        _client?.Close();
        _state = ConnectionState.Closed;
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
        _client?.Begin();
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
