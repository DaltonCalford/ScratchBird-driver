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
using System.Text.RegularExpressions;
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
    private ScratchBirdTransaction? _activeTransaction;
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
        _activeTransaction = null;

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
        _activeTransaction = null;
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
        _activeTransaction = null;
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
        if (HasActiveTransaction)
        {
            throw new InvalidOperationException("Connection already has an active transaction");
        }

        GetConnectedClient().Begin(isolationLevel);
        var transaction = new ScratchBirdTransaction(this, isolationLevel);
        _activeTransaction = transaction;
        return transaction;
    }

    internal bool HasActiveTransaction
    {
        get
        {
            if (_activeTransaction != null && _activeTransaction.IsCompleted)
            {
                _activeTransaction = null;
            }

            return _activeTransaction != null;
        }
    }

    internal bool IsActiveTransaction(ScratchBirdTransaction transaction)
    {
        ArgumentNullException.ThrowIfNull(transaction);
        return ReferenceEquals(_activeTransaction, transaction) && !_activeTransaction.IsCompleted;
    }

    internal void CompleteTransaction(ScratchBirdTransaction transaction)
    {
        if (_activeTransaction != null && ReferenceEquals(_activeTransaction, transaction))
        {
            _activeTransaction = null;
        }
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

        var collectionKey = NormalizeCollectionName(collectionName);

        var query = collectionKey switch
        {
            "tables" => ScratchBirdMetadata.TablesQuery,
            "columns" => ScratchBirdMetadata.ColumnsQuery,
            "schemas" => ScratchBirdMetadata.SchemasQuery,
            "indexes" => ScratchBirdMetadata.IndexesQuery,
            "indexcolumns" => ScratchBirdMetadata.IndexColumnsQuery,
            "constraints" => ScratchBirdMetadata.ConstraintsQuery,
            "procedures" => ScratchBirdMetadata.ProceduresQuery,
            "functions" => ScratchBirdMetadata.FunctionsQuery,
            _ => throw new NotSupportedException($"Schema collection '{collectionName}' is not supported")
        };

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

        return ShapeMetadataTable(table, collectionKey, restrictionValues, _config.MetadataExpandSchemaParents);
    }

    private static string NormalizeCollectionName(string? collectionName)
    {
        return collectionName?.ToLowerInvariant() switch
        {
            null or "" or "tables" => "tables",
            "columns" => "columns",
            "schemas" => "schemas",
            "indexes" => "indexes",
            "indexcolumns" or "index_columns" => "indexcolumns",
            "constraints" => "constraints",
            "procedures" => "procedures",
            "functions" => "functions",
            _ => collectionName?.ToLowerInvariant() ?? string.Empty
        };
    }

    internal static DataTable ShapeMetadataTable(
        DataTable table,
        string collectionKey,
        string?[]? restrictionValues,
        bool expandSchemaParents)
    {
        var shaped = table;
        if (expandSchemaParents && string.Equals(collectionKey, "schemas", StringComparison.Ordinal))
        {
            shaped = ExpandSchemaParentsForMetadata(shaped);
        }

        return ApplyRestrictionValuesForMetadata(shaped, collectionKey, restrictionValues);
    }

    internal static DataTable ExpandSchemaParentsForMetadata(DataTable table)
    {
        var schemaColumn = ResolveColumnName(table, "schema_name", "table_schema", "table_schem");
        if (schemaColumn == null)
        {
            return table;
        }

        var schemaNames = table.Rows.Cast<DataRow>()
            .Select(row => row[schemaColumn] == DBNull.Value ? null : row[schemaColumn]?.ToString())
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Select(name => name!.Trim())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        if (schemaNames.Count == 0)
        {
            return table;
        }

        var expanded = new HashSet<string>(schemaNames, StringComparer.OrdinalIgnoreCase);
        foreach (var schemaName in schemaNames)
        {
            AppendSchemaParents(expanded, schemaName);
        }

        if (expanded.Count == schemaNames.Count)
        {
            return table;
        }

        var existingRows = table.Rows.Cast<DataRow>()
            .Where(row => row[schemaColumn] != DBNull.Value)
            .GroupBy(row => row[schemaColumn]?.ToString() ?? string.Empty, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => group.First(), StringComparer.OrdinalIgnoreCase);

        var result = table.Clone();
        foreach (var schemaName in expanded.OrderBy(name => name, StringComparer.OrdinalIgnoreCase))
        {
            if (existingRows.TryGetValue(schemaName, out var existing))
            {
                result.ImportRow(existing);
                continue;
            }

            var synthetic = result.NewRow();
            synthetic[schemaColumn] = schemaName;
            result.Rows.Add(synthetic);
        }

        return result;
    }

    internal static DataTable ApplyRestrictionValuesForMetadata(
        DataTable table,
        string collectionKey,
        string?[]? restrictionValues)
    {
        if (restrictionValues == null || restrictionValues.Length == 0)
        {
            return table;
        }

        var restrictionColumns = ResolveRestrictionColumns(table, collectionKey);
        if (restrictionColumns.Count == 0)
        {
            return table;
        }

        var filtered = table.Clone();
        foreach (DataRow row in table.Rows)
        {
            if (!RowMatchesRestrictions(row, restrictionValues, restrictionColumns))
            {
                continue;
            }
            filtered.ImportRow(row);
        }

        return filtered;
    }

    private static Dictionary<int, string> ResolveRestrictionColumns(DataTable table, string collectionKey)
    {
        var resolved = new Dictionary<int, string>();
        foreach (var (index, aliases) in RestrictionColumnAliases(collectionKey))
        {
            var column = ResolveColumnName(table, aliases);
            if (column != null)
            {
                resolved[index] = column;
            }
        }
        return resolved;
    }

    private static IEnumerable<(int index, string[] aliases)> RestrictionColumnAliases(string collectionKey)
    {
        return collectionKey switch
        {
            "tables" =>
            [
                (1, new[] { "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME" }),
                (3, new[] { "table_type", "TABLE_TYPE" })
            ],
            "columns" =>
            [
                (1, new[] { "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME" }),
                (3, new[] { "column_name", "COLUMN_NAME" })
            ],
            "schemas" =>
            [
                (0, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" })
            ],
            _ => Array.Empty<(int, string[])>()
        };
    }

    private static bool RowMatchesRestrictions(DataRow row, IReadOnlyList<string?> restrictionValues, IReadOnlyDictionary<int, string> restrictionColumns)
    {
        for (var i = 0; i < restrictionValues.Count; i++)
        {
            var restriction = restrictionValues[i];
            if (string.IsNullOrWhiteSpace(restriction))
            {
                continue;
            }
            if (!restrictionColumns.TryGetValue(i, out var columnName))
            {
                continue;
            }

            var value = row[columnName] == DBNull.Value ? string.Empty : row[columnName]?.ToString() ?? string.Empty;
            if (!MatchesRestriction(value, restriction))
            {
                return false;
            }
        }

        return true;
    }

    private static bool MatchesRestriction(string value, string pattern)
    {
        if (pattern.IndexOf('%') < 0 && pattern.IndexOf('_') < 0)
        {
            return string.Equals(value, pattern, StringComparison.OrdinalIgnoreCase);
        }

        var regexBuilder = new StringBuilder("^");
        foreach (var ch in pattern)
        {
            if (ch == '%')
            {
                regexBuilder.Append(".*");
                continue;
            }
            if (ch == '_')
            {
                regexBuilder.Append('.');
                continue;
            }
            regexBuilder.Append(Regex.Escape(ch.ToString()));
        }
        regexBuilder.Append('$');

        var regexPattern = regexBuilder.ToString();
        return Regex.IsMatch(value, regexPattern, RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);
    }

    private static void AppendSchemaParents(ISet<string> output, string schemaName)
    {
        if (string.IsNullOrWhiteSpace(schemaName))
        {
            return;
        }

        var segments = schemaName.Split('.', StringSplitOptions.None);
        var current = new StringBuilder();
        foreach (var segmentRaw in segments)
        {
            var segment = segmentRaw.Trim();
            if (segment.Length == 0)
            {
                continue;
            }

            if (current.Length > 0)
            {
                current.Append('.');
            }
            current.Append(segment);
            output.Add(current.ToString());
        }
    }

    private static string? ResolveColumnName(DataTable table, params string[] aliases)
    {
        foreach (var alias in aliases)
        {
            foreach (DataColumn column in table.Columns)
            {
                if (string.Equals(column.ColumnName, alias, StringComparison.OrdinalIgnoreCase))
                {
                    return column.ColumnName;
                }
            }
        }

        return null;
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
