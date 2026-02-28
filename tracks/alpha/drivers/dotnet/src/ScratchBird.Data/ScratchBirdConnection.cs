// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data;
using System.Data.Common;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;

namespace ScratchBird.Data;

public sealed class ScratchBirdConnection : DbConnection
{
    private const int MaxConnectRetries = 3;
    private const int ReconnectBackoffMs = 120;
    private const int MinConnectTimeoutMs = 1;

    private string _connectionString = string.Empty;
    private ConnectionState _state = ConnectionState.Closed;
    private ScratchBirdConfig _config = new();
    private ProtocolClient? _client;
    private ProtocolClientPool.Lease? _clientLease;
    private bool _disposed;

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

    private void OpenWithRetry(CancellationToken cancellationToken)
    {
        ScratchBirdException? lastFailure = null;

        for (var attempt = 0; attempt < MaxConnectRetries; attempt++)
        {
            cancellationToken.ThrowIfCancellationRequested();
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
                    var retryDelayMs = Math.Max(MinConnectTimeoutMs, Math.Min(ReconnectBackoffMs * (1 << attempt), 1000));
                    if (cancellationToken.WaitHandle.WaitOne(retryDelayMs))
                    {
                        cancellationToken.ThrowIfCancellationRequested();
                    }
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

    private void OpenWithRetry()
    {
        OpenWithRetry(CancellationToken.None);
    }

    private void BorrowAndConnect()
    {
        _clientLease?.Dispose();
        _clientLease = null;

        _client = ProtocolClientPool.BorrowOrCreate(_config, out var lease);
        _clientLease = lease;
        try
        {
            if (!_client.IsHealthy)
            {
                _client.Connect(_config);
            }
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
        if (_state != ConnectionState.Closed)
        {
            return;
        }

        await Task.Run(() => OpenWithRetry(cancellationToken), cancellationToken);
    }

    public override void Close()
    {
        if (_disposed)
        {
            return;
        }

        var lease = _clientLease;
        _clientLease = null;
        _client = null;
        _state = ConnectionState.Closed;
        lease?.Dispose();
    }

    protected override void Dispose(bool disposing)
    {
        if (_disposed)
        {
            base.Dispose(disposing);
            return;
        }

        if (disposing)
        {
            Close();
        }
        _disposed = true;
        base.Dispose(disposing);
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

    public override System.Data.DataTable GetSchema()
    {
        return GetSchema("Tables");
    }

    public override System.Data.DataTable GetSchema(string collectionName)
    {
        return GetSchema(collectionName, null);
    }

    public override System.Data.DataTable GetSchema(string collectionName, string[]? restrictionValues)
    {
        if (_state != ConnectionState.Open)
        {
            throw new InvalidOperationException("Connection is not open");
        }

        var query = collectionName?.ToLowerInvariant() switch
        {
            null or "" or "tables" => ScratchBirdMetadata.TablesQuery,
            "columns" => ScratchBirdMetadata.ColumnsQuery,
            "schemas" => ScratchBirdMetadata.SchemasQuery,
            "indexes" => ScratchBirdMetadata.IndexesQuery,
            "indexcolumns" or "index_columns" => ScratchBirdMetadata.IndexColumnsQuery,
            "constraints" => ScratchBirdMetadata.ConstraintsQuery,
            "procedures" => ScratchBirdMetadata.ProceduresQuery,
            "functions" => ScratchBirdMetadata.FunctionsQuery,
            _ => throw new NotSupportedException($"Schema collection '{collectionName}' is not supported")
        };

        _ = restrictionValues;

        using var cmd = CreateDbCommand();
        cmd.CommandText = query;
        using var reader = cmd.ExecuteReader();
        _ = reader.HasRows; // Prime row-description metadata before FieldCount/column enumeration.

        var table = new System.Data.DataTable(collectionName);
        for (var i = 0; i < reader.FieldCount; i++)
        {
            table.Columns.Add(reader.GetName(i), reader.GetFieldType(i));
        }

        while (reader.Read())
        {
            var row = table.NewRow();
            for (var i = 0; i < reader.FieldCount; i++)
            {
                row[i] = reader.IsDBNull(i) ? DBNull.Value : reader.GetValue(i);
            }
            table.Rows.Add(row);
        }

        return table;
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
            var parts = SplitTopLevel(trimmed, ',')
                .Select(part => part.Trim())
                .Where(part => !string.IsNullOrWhiteSpace(part))
                .Select(FormatSchemaPath)
                .ToArray();
            if (parts.Length == 0)
            {
                return string.Empty;
            }
            return $"SET SEARCH_PATH TO {string.Join(", ", parts)}";
        }
        return $"SET SCHEMA {FormatSchemaPath(trimmed)}";
    }

    private static string FormatSchemaPath(string schemaPath)
    {
        var segments = SplitTopLevel(schemaPath, '.')
            .Select(segment => segment.Trim())
            .Where(segment => !string.IsNullOrWhiteSpace(segment))
            .Select(NormalizeIdentifierSegment)
            .ToArray();
        if (segments.Length == 0)
        {
            return QuoteIdentifier(schemaPath.Trim());
        }
        return string.Join(".", segments);
    }

    private static string NormalizeIdentifierSegment(string segment)
    {
        if (segment.Length >= 2 && segment.StartsWith('"') && segment.EndsWith('"'))
        {
            return segment;
        }
        return QuoteIdentifier(segment);
    }

    private static string QuoteIdentifier(string name)
    {
        return $"\"{name.Replace("\"", "\"\"")}\"";
    }

    private static IReadOnlyList<string> SplitTopLevel(string value, char delimiter)
    {
        var tokens = new List<string>();
        if (string.IsNullOrWhiteSpace(value))
        {
            return tokens;
        }

        var sb = new StringBuilder();
        var inDouble = false;
        for (var i = 0; i < value.Length; i++)
        {
            var c = value[i];
            if (c == '"')
            {
                sb.Append(c);
                if (inDouble && i + 1 < value.Length && value[i + 1] == '"')
                {
                    sb.Append('"');
                    i++;
                    continue;
                }
                inDouble = !inDouble;
                continue;
            }
            if (!inDouble && c == delimiter)
            {
                tokens.Add(sb.ToString());
                sb.Clear();
                continue;
            }
            sb.Append(c);
        }
        tokens.Add(sb.ToString());
        return tokens;
    }
}
