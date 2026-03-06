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
using System.Diagnostics;
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
    private TelemetryCollector _telemetry = new();
    private CircuitBreaker _circuitBreaker = new();
    private readonly object _notificationSync = new();
    private Queue<ScratchBirdNotification>? _notificationQueue;
    private HashSet<Action<ScratchBirdNotification>>? _notificationListeners;
    private ProtocolClient? _notificationBridgeClient;
    private bool _notificationBridgeRequested;

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
            _telemetry = new TelemetryCollector(BuildTelemetryOptions(_config));
            _circuitBreaker = new CircuitBreaker(BuildCircuitBreakerOptions(_config));
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

        TrackOperation("Connection.Open", () =>
        {
            OpenWithRetry();
            _state = ConnectionState.Open;
        });
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
            InstallNotificationBridgeIfNeeded(_client);
        }
        catch
        {
            _clientLease?.Dispose();
            _clientLease = null;
            _client = null;
            lock (_notificationSync)
            {
                _notificationBridgeClient = null;
            }
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

        var stopwatch = Stopwatch.StartNew();
        var success = false;
        try
        {
            await Task.Run(() => OpenWithRetry(cancellationToken), cancellationToken);
            success = true;
        }
        finally
        {
            RecordTelemetry("Connection.OpenAsync", stopwatch.Elapsed, success);
        }
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
        lock (_notificationSync)
        {
            _notificationBridgeClient = null;
        }
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
        return TrackOperation("Connection.BeginTransaction", () =>
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
            return (DbTransaction)transaction;
        });
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

    public string NativeSql(string sql, IReadOnlyList<ScratchBirdParameter>? parameters = null)
    {
        var normalized = SqlHelpers.Normalize(sql, NormalizeParameterList(parameters));
        return normalized.Sql;
    }

    public string NativeCallableSql(string sql, IReadOnlyList<ScratchBirdParameter>? parameters = null)
    {
        var normalized = SqlHelpers.NormalizeCallable(sql, NormalizeParameterList(parameters));
        return normalized.Sql;
    }

    public ConnectionDiagnosticsSummary GetDiagnostics()
    {
        var client = _client;
        return new ConnectionDiagnosticsSummary(
            DateTimeOffset.UtcNow,
            _state,
            client?.IsHealthy ?? false,
            _config.FrontDoorMode,
            _config.Protocol,
            _config.Host,
            _config.Port,
            _config.Database,
            _config.Pooling,
            GetPoolDiagnostics(),
            CreateQueryPlanSummary(client?.LastPlan),
            CreateSblrSummary(client?.LastSblr),
            MapCircuitBreakerSummary(_circuitBreaker.Snapshot()));
    }

    public ConnectionTelemetrySummary GetTelemetrySummary()
    {
        return _telemetry.Snapshot();
    }

    public void ResetTelemetry()
    {
        _telemetry.Reset();
    }

    public IReadOnlyList<SlowOperationSummary> GetSlowOperations()
    {
        return _telemetry.GetSlowOperations();
    }

    public string ExportTelemetryPrometheus()
    {
        return _telemetry.ExportPrometheusMetrics();
    }

    public CircuitBreakerSummary GetCircuitBreakerSummary()
    {
        return MapCircuitBreakerSummary(_circuitBreaker.Snapshot());
    }

    public PoolDiagnosticsSummary? GetPoolDiagnostics()
    {
        return MapPoolDiagnostics(ProtocolClientPool.GetStats(_config));
    }

    public static PoolDiagnosticsSummary? GetPoolDiagnostics(string connectionString)
    {
        var config = ScratchBirdConfig.FromConnectionString(connectionString);
        return MapPoolDiagnostics(ProtocolClientPool.GetStats(config));
    }

    internal void RecordTelemetry(string operation, TimeSpan duration, bool success, string? statement = null)
    {
        _telemetry.Record(operation, duration, success, statement);
    }

    private T TrackOperation<T>(string operation, Func<T> action)
    {
        if (!_circuitBreaker.AllowRequest())
        {
            RecordTelemetry(operation, TimeSpan.Zero, success: false);
            throw new ScratchBirdConnectionException("Circuit breaker is OPEN", "08006");
        }

        var stopwatch = Stopwatch.StartNew();
        var success = false;
        try
        {
            var result = action();
            success = true;
            return result;
        }
        catch
        {
            _circuitBreaker.RecordFailure();
            throw;
        }
        finally
        {
            if (success)
            {
                _circuitBreaker.RecordSuccess();
            }

            RecordTelemetry(operation, stopwatch.Elapsed, success);
        }
    }

    private void TrackOperation(string operation, Action action)
    {
        _ = TrackOperation(operation, () =>
        {
            action();
            return 0;
        });
    }

    public void Listen(string channel, string filterExpr = "")
    {
        Subscribe(ScratchBirdSubscriptionType.Channel, channel, filterExpr);
    }

    public void Unlisten(string channel)
    {
        Unsubscribe(channel);
    }

    public void UnlistenAll()
    {
        TrackOperation("Connection.UnlistenAll", () => ExecuteControlCommand("UNLISTEN *"));
    }

    public void Subscribe(ScratchBirdSubscriptionType subscriptionType, string channel, string filterExpr = "")
    {
        var normalizedChannel = NormalizeNotificationChannel(channel);
        var normalizedFilter = filterExpr ?? string.Empty;
        TrackOperation("Connection.Subscribe", () =>
        {
            var client = EnsureNotificationBridge();
            client.Subscribe((byte)subscriptionType, normalizedChannel, normalizedFilter);
        });
    }

    public void Unsubscribe(string channel)
    {
        var normalizedChannel = NormalizeNotificationChannel(channel);
        TrackOperation("Connection.Unsubscribe", () =>
        {
            var client = EnsureConnectedClient();
            client.Unsubscribe(normalizedChannel);
        });
    }

    public void NotifyChannel(string channel)
    {
        NotifyChannel(channel, (string?)null);
    }

    public void NotifyChannel(string channel, byte[]? payload)
    {
        if (payload == null)
        {
            NotifyChannel(channel, (string?)null);
            return;
        }

        NotifyChannel(channel, Encoding.UTF8.GetString(payload));
    }

    public void NotifyChannel(string channel, string? payload)
    {
        var sql = BuildNotifyCommand(channel, payload);
        TrackOperation("Connection.NotifyChannel", () => ExecuteControlCommand(sql));
    }

    public void AddNotificationListener(Action<ScratchBirdNotification> listener)
    {
        ArgumentNullException.ThrowIfNull(listener);
        EnsureNotificationBridge();
        lock (_notificationSync)
        {
            _notificationListeners ??= new HashSet<Action<ScratchBirdNotification>>();
            _notificationListeners.Add(listener);
        }
    }

    public bool RemoveNotificationListener(Action<ScratchBirdNotification> listener)
    {
        ArgumentNullException.ThrowIfNull(listener);
        EnsureNotificationBridge();
        lock (_notificationSync)
        {
            return _notificationListeners != null && _notificationListeners.Remove(listener);
        }
    }

    public ScratchBirdNotification? GetNotification()
    {
        EnsureNotificationBridge();
        lock (_notificationSync)
        {
            if (_notificationQueue == null || _notificationQueue.Count == 0)
            {
                return null;
            }

            return CloneNotification(_notificationQueue.Dequeue());
        }
    }

    public IReadOnlyList<ScratchBirdNotification> GetNotifications()
    {
        EnsureNotificationBridge();
        lock (_notificationSync)
        {
            if (_notificationQueue == null || _notificationQueue.Count == 0)
            {
                return Array.Empty<ScratchBirdNotification>();
            }

            var drained = new List<ScratchBirdNotification>(_notificationQueue.Count);
            while (_notificationQueue.Count > 0)
            {
                drained.Add(CloneNotification(_notificationQueue.Dequeue()));
            }
            return drained;
        }
    }

    public void ClearNotifications()
    {
        EnsureNotificationBridge();
        lock (_notificationSync)
        {
            _notificationQueue?.Clear();
        }
    }

    internal void AcceptNotification(
        uint processId,
        string channel,
        byte[] payload,
        char? changeType,
        ulong? rowId)
    {
        var notification = new ScratchBirdNotification(
            processId,
            channel,
            CloneBytes(payload),
            changeType,
            rowId,
            DateTimeOffset.UtcNow);
        Action<ScratchBirdNotification>[] listeners;
        lock (_notificationSync)
        {
            (_notificationQueue ??= new Queue<ScratchBirdNotification>()).Enqueue(notification);
            listeners = _notificationListeners?.ToArray() ?? Array.Empty<Action<ScratchBirdNotification>>();
        }

        foreach (var listener in listeners)
        {
            try
            {
                listener(CloneNotification(notification));
            }
            catch
            {
                // Consumer listener exceptions must not break connection protocol handling.
            }
        }
    }

    public ResultSetSummary Call(
        string sql,
        IReadOnlyList<ScratchBirdParameter>? parameters = null,
        int commandTimeoutSeconds = 30,
        int fetchSize = 0)
    {
        return TrackOperation("Connection.Call", () =>
        {
            var normalized = SqlHelpers.NormalizeCallable(sql, NormalizeParameterList(parameters));
            var resultSets = ExecuteQueryMultiInternal(
                normalized.Sql,
                normalized.Parameters,
                commandTimeoutSeconds,
                fetchSize);
            var preferred = resultSets.LastOrDefault(set => set.Rows.Count > 0);
            if (preferred != null)
            {
                return preferred;
            }
            return resultSets.Count > 0
                ? resultSets[^1]
                : new ResultSetSummary(
                    Array.Empty<object?[]>(),
                    0,
                    Array.Empty<FieldSummary>(),
                    string.Empty,
                    0);
        });
    }

    public IReadOnlyList<ResultSetSummary> QueryMulti(
        string sql,
        IReadOnlyList<ScratchBirdParameter>? parameters = null,
        int commandTimeoutSeconds = 30,
        int fetchSize = 0)
    {
        return TrackOperation("Connection.QueryMulti", () =>
        {
            var normalized = SqlHelpers.Normalize(sql, NormalizeParameterList(parameters));
            if (normalized.Parameters.Count == 0)
            {
                var statements = SplitSqlStatements(normalized.Sql);
                if (statements.Count > 1)
                {
                    var expanded = new List<ResultSetSummary>();
                    foreach (var statement in statements)
                    {
                        if (string.IsNullOrWhiteSpace(statement))
                        {
                            continue;
                        }
                        expanded.AddRange(ExecuteQueryMultiInternal(
                            statement,
                            Array.Empty<ScratchBirdParameter>(),
                            commandTimeoutSeconds,
                            fetchSize));
                    }
                    return (IReadOnlyList<ResultSetSummary>)expanded;
                }
            }

            return ExecuteQueryMultiInternal(
                normalized.Sql,
                normalized.Parameters,
                commandTimeoutSeconds,
                fetchSize);
        });
    }

    public IReadOnlyList<ResultSetSummary> ExecuteMulti(
        string sql,
        IReadOnlyList<ScratchBirdParameter>? parameters = null,
        int commandTimeoutSeconds = 30,
        int fetchSize = 0)
    {
        return QueryMulti(sql, parameters, commandTimeoutSeconds, fetchSize);
    }

    public BatchSummary ExecuteBatch(
        string sql,
        IReadOnlyList<IReadOnlyList<ScratchBirdParameter>> batchParameters,
        int commandTimeoutSeconds = 30,
        int fetchSize = 0)
    {
        return TrackOperation("Connection.ExecuteBatch", () =>
        {
            ArgumentNullException.ThrowIfNull(batchParameters);
            if (batchParameters.Count == 0)
            {
                throw new ArgumentException("batch parameters are required", nameof(batchParameters));
            }

            var items = new List<BatchItemSummary>(batchParameters.Count);
            long totalRowCount = 0;
            for (var i = 0; i < batchParameters.Count; i++)
            {
                var currentParameters = batchParameters[i] ?? Array.Empty<ScratchBirdParameter>();
                var resultSets = QueryMulti(sql, currentParameters, commandTimeoutSeconds, fetchSize);
                long rowCount = 0;
                IReadOnlyList<FieldSummary> fields = Array.Empty<FieldSummary>();
                var command = string.Empty;
                long lastInsertId = 0;

                foreach (var set in resultSets)
                {
                    if (set.RowCount > 0)
                    {
                        rowCount += set.RowCount;
                    }
                    if (set.Fields.Count > 0)
                    {
                        fields = set.Fields;
                    }
                    if (!string.IsNullOrEmpty(set.Command))
                    {
                        command = set.Command;
                    }
                    if (set.LastInsertId != 0)
                    {
                        lastInsertId = set.LastInsertId;
                    }
                }

                if (rowCount > 0)
                {
                    totalRowCount += rowCount;
                }

                items.Add(new BatchItemSummary(i, rowCount, fields, command, lastInsertId));
            }

            return new BatchSummary(items, totalRowCount);
        });
    }

    public BatchSummary QueryBatch(
        string sql,
        IReadOnlyList<IReadOnlyList<ScratchBirdParameter>> batchParameters,
        int commandTimeoutSeconds = 30,
        int fetchSize = 0)
    {
        return ExecuteBatch(sql, batchParameters, commandTimeoutSeconds, fetchSize);
    }

    public IReadOnlyList<long> ExecuteWithGeneratedKeys(
        string sql,
        IReadOnlyList<ScratchBirdParameter>? parameters = null,
        int commandTimeoutSeconds = 30,
        int fetchSize = 0)
    {
        return TrackOperation("Connection.ExecuteWithGeneratedKeys", () =>
        {
            var resultSets = QueryMulti(sql, parameters, commandTimeoutSeconds, fetchSize);
            return (IReadOnlyList<long>)resultSets
                .Where(set => set.LastInsertId != 0)
                .Select(set => set.LastInsertId)
                .ToArray();
        });
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
        return TrackOperation("Connection.GetSchema", () =>
        {
            if (_state != ConnectionState.Open)
            {
                throw new InvalidOperationException("Connection is not open");
            }

            var collectionKey = NormalizeCollectionName(collectionName);
            if (string.Equals(collectionKey, "catalogs", StringComparison.Ordinal))
            {
                return BuildCatalogsMetadataTable(collectionName, restrictionValues);
            }

            var query = collectionKey switch
            {
                "catalogs" => ScratchBirdMetadata.CatalogsQuery,
                "tables" => ScratchBirdMetadata.TablesQuery,
                "columns" => ScratchBirdMetadata.ColumnsQuery,
                "schemas" => ScratchBirdMetadata.SchemasQuery,
                "indexes" => ScratchBirdMetadata.IndexesQuery,
                "indexcolumns" => ScratchBirdMetadata.IndexColumnsQuery,
                "constraints" => ScratchBirdMetadata.ConstraintsQuery,
                "primarykeys" => ScratchBirdMetadata.PrimaryKeysQuery,
                "foreignkeys" => ScratchBirdMetadata.ForeignKeysQuery,
                "tableprivileges" => ScratchBirdMetadata.TablePrivilegesQuery,
                "columnprivileges" => ScratchBirdMetadata.ColumnPrivilegesQuery,
                "procedures" => ScratchBirdMetadata.ProceduresQuery,
                "functions" => ScratchBirdMetadata.FunctionsQuery,
                "routines" => ScratchBirdMetadata.RoutinesQuery,
                "typeinfo" => ScratchBirdMetadata.TypeInfoQuery,
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
        });
    }

    private static string NormalizeCollectionName(string? collectionName)
    {
        return collectionName?.ToLowerInvariant() switch
        {
            "catalog" or "catalogs" => "catalogs",
            null or "" or "tables" => "tables",
            "columns" => "columns",
            "schemas" => "schemas",
            "indexes" => "indexes",
            "indexcolumns" or "index_columns" => "indexcolumns",
            "constraints" => "constraints",
            "primarykey" or "primarykeys" or "primary_keys" or "pk" => "primarykeys",
            "foreignkey" or "foreignkeys" or "foreign_keys" or "fk" => "foreignkeys",
            "tableprivileges" or "table_privileges" => "tableprivileges",
            "columnprivileges" or "column_privileges" => "columnprivileges",
            "procedures" => "procedures",
            "functions" => "functions",
            "routine" or "routines" => "routines",
            "typeinfo" or "type_info" or "types" => "typeinfo",
            _ => collectionName?.ToLowerInvariant() ?? string.Empty
        };
    }

    private DataTable BuildCatalogsMetadataTable(string collectionName, string?[]? restrictionValues)
    {
        var table = new DataTable(collectionName);
        table.Columns.Add("table_catalog", typeof(string));
        if (!string.IsNullOrWhiteSpace(_config.Database))
        {
            var row = table.NewRow();
            row["table_catalog"] = _config.Database;
            table.Rows.Add(row);
        }

        return ApplyRestrictionValuesForMetadata(table, "catalogs", restrictionValues);
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
            "indexes" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "index_name", "INDEX_NAME", "index_id", "INDEX_ID" })
            ],
            "indexcolumns" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "index_name", "INDEX_NAME", "index_id", "INDEX_ID" }),
                (4, new[] { "column_name", "COLUMN_NAME", "column_id", "COLUMN_ID" })
            ],
            "constraints" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "constraint_name", "CONSTRAINT_NAME", "pk_name", "PK_NAME", "fk_name", "FK_NAME" })
            ],
            "primarykeys" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "constraint_name", "CONSTRAINT_NAME", "pk_name", "PK_NAME" })
            ],
            "foreignkeys" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "constraint_name", "CONSTRAINT_NAME", "fk_name", "FK_NAME" })
            ],
            "schemas" =>
            [
                (0, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" })
            ],
            "catalogs" =>
            [
                (0, new[] { "table_catalog", "TABLE_CATALOG", "catalog_name", "CATALOG_NAME" })
            ],
            "tableprivileges" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "grantor", "GRANTOR", "grantor_id", "GRANTOR_ID", "grantee", "GRANTEE", "grantee_id", "GRANTEE_ID" })
            ],
            "columnprivileges" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "table_schema", "TABLE_SCHEMA", "table_schem", "TABLE_SCHEM" }),
                (2, new[] { "table_name", "TABLE_NAME", "table_id", "TABLE_ID" }),
                (3, new[] { "column_name", "COLUMN_NAME", "column_id", "COLUMN_ID" }),
                (4, new[] { "grantor", "GRANTOR", "grantor_id", "GRANTOR_ID", "grantee", "GRANTEE", "grantee_id", "GRANTEE_ID" })
            ],
            "procedures" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "specific_schema", "SPECIFIC_SCHEMA", "routine_schema", "ROUTINE_SCHEMA", "schema_id", "SCHEMA_ID" }),
                (2, new[] { "procedure_name", "PROCEDURE_NAME", "routine_name", "ROUTINE_NAME", "specific_name", "SPECIFIC_NAME" })
            ],
            "functions" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "specific_schema", "SPECIFIC_SCHEMA", "routine_schema", "ROUTINE_SCHEMA", "schema_id", "SCHEMA_ID" }),
                (2, new[] { "function_name", "FUNCTION_NAME", "routine_name", "ROUTINE_NAME", "specific_name", "SPECIFIC_NAME" })
            ],
            "routines" =>
            [
                (1, new[] { "schema_name", "SCHEMA_NAME", "specific_schema", "SPECIFIC_SCHEMA", "routine_schema", "ROUTINE_SCHEMA", "schema_id", "SCHEMA_ID" }),
                (2, new[] { "routine_name", "ROUTINE_NAME", "function_name", "FUNCTION_NAME", "procedure_name", "PROCEDURE_NAME", "specific_name", "SPECIFIC_NAME" })
            ],
            "typeinfo" =>
            [
                (0, new[] { "type_name", "TYPE_NAME", "data_type_name", "DATA_TYPE_NAME", "udt_name", "UDT_NAME", "data_type", "DATA_TYPE" })
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

            var rawValue = row[columnName];
            if (IsNullRestriction(restriction))
            {
                if (rawValue != DBNull.Value && rawValue != null)
                {
                    return false;
                }
                continue;
            }

            var value = rawValue == DBNull.Value ? string.Empty : rawValue?.ToString() ?? string.Empty;
            if (!MatchesRestriction(value, restriction))
            {
                return false;
            }
        }

        return true;
    }

    private static bool IsNullRestriction(string pattern)
    {
        return string.Equals(pattern.Trim(), "null", StringComparison.OrdinalIgnoreCase);
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

    internal static PoolDiagnosticsSummary? MapPoolDiagnostics(ProtocolClientPool.PoolStats? stats)
    {
        if (!stats.HasValue)
        {
            return null;
        }

        var value = stats.Value;
        return new PoolDiagnosticsSummary(
            value.ActiveCount,
            value.IdleCount,
            value.MaxSize,
            value.MinSize,
            value.BorrowAttempts,
            value.Borrowed,
            value.Returned,
            value.Rejected,
            value.Evicted);
    }

    internal static QueryPlanSummary? CreateQueryPlanSummary(
        (uint Format, ulong PlanningTimeUs, ulong EstimatedRows, ulong EstimatedCost, byte[] Plan)? plan)
    {
        if (!plan.HasValue)
        {
            return null;
        }

        var value = plan.Value;
        return new QueryPlanSummary(
            value.Format,
            value.PlanningTimeUs,
            value.EstimatedRows,
            value.EstimatedCost,
            CloneBytes(value.Plan));
    }

    internal static SblrSummary? CreateSblrSummary((ulong Hash, uint Version, byte[] Bytecode)? sblr)
    {
        if (!sblr.HasValue)
        {
            return null;
        }

        var value = sblr.Value;
        return new SblrSummary(
            value.Hash,
            value.Version,
            CloneBytes(value.Bytecode));
    }

    private static CircuitBreakerSummary MapCircuitBreakerSummary(CircuitBreakerSnapshot snapshot)
    {
        return new CircuitBreakerSummary(
            snapshot.Enabled,
            snapshot.State,
            snapshot.FailureCount,
            snapshot.SuccessCount,
            snapshot.HalfOpenRequests,
            snapshot.FailureThreshold,
            snapshot.SuccessThreshold,
            snapshot.HalfOpenMaxRequests,
            snapshot.RecoveryTimeoutMs,
            snapshot.LastFailureUtc);
    }

    private ProtocolClient EnsureNotificationBridge()
    {
        lock (_notificationSync)
        {
            _notificationBridgeRequested = true;
        }

        var client = EnsureConnectedClient();
        InstallNotificationBridgeIfNeeded(client);
        return client;
    }

    private void InstallNotificationBridgeIfNeeded(ProtocolClient client)
    {
        lock (_notificationSync)
        {
            if (!_notificationBridgeRequested || ReferenceEquals(_notificationBridgeClient, client))
            {
                return;
            }

            client.OnNotification(AcceptNotification);
            _notificationBridgeClient = client;
        }
    }

    private static ScratchBirdNotification CloneNotification(ScratchBirdNotification notification)
    {
        return notification with { Payload = CloneBytes(notification.Payload) };
    }

    internal static string NormalizeNotificationChannel(string? channel)
    {
        if (channel == null)
        {
            throw new ArgumentException("Notification channel cannot be null", nameof(channel));
        }

        var normalized = channel.Trim();
        if (normalized.Length == 0)
        {
            throw new ArgumentException("Notification channel cannot be empty", nameof(channel));
        }

        if (normalized.IndexOf('\0') >= 0)
        {
            throw new ArgumentException("Notification channel cannot contain NUL bytes", nameof(channel));
        }

        return normalized;
    }

    internal static string BuildNotifyCommand(string channel, string? payload)
    {
        var normalizedChannel = NormalizeNotificationChannel(channel);
        var sql = $"NOTIFY {QuoteIdentifier(normalizedChannel)}";
        if (payload == null)
        {
            return sql;
        }

        if (payload.IndexOf('\0') >= 0)
        {
            throw new ArgumentException("Notification payload cannot contain NUL bytes", nameof(payload));
        }

        return $"{sql}, {QuoteSqlLiteral(payload)}";
    }

    private static byte[] CloneBytes(byte[]? value)
    {
        if (value == null || value.Length == 0)
        {
            return Array.Empty<byte>();
        }

        return (byte[])value.Clone();
    }

    private void ExecuteControlCommand(string sql)
    {
        _ = ExecuteQueryMultiInternal(sql, Array.Empty<ScratchBirdParameter>(), commandTimeoutSeconds: 30, fetchSize: 0);
    }

    private static string QuoteSqlLiteral(string value)
    {
        return $"'{value.Replace("'", "''", StringComparison.Ordinal)}'";
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

    private static IReadOnlyList<string> SplitSqlStatements(string sql)
    {
        if (string.IsNullOrWhiteSpace(sql))
        {
            return Array.Empty<string>();
        }

        var statements = new List<string>();
        var builder = new StringBuilder();
        var inSingle = false;
        var inDouble = false;
        for (var i = 0; i < sql.Length; i++)
        {
            var ch = sql[i];
            if (ch == '\'' && !inDouble)
            {
                builder.Append(ch);
                if (inSingle && i + 1 < sql.Length && sql[i + 1] == '\'')
                {
                    builder.Append('\'');
                    i++;
                    continue;
                }
                inSingle = !inSingle;
                continue;
            }
            if (ch == '"' && !inSingle)
            {
                builder.Append(ch);
                if (inDouble && i + 1 < sql.Length && sql[i + 1] == '"')
                {
                    builder.Append('"');
                    i++;
                    continue;
                }
                inDouble = !inDouble;
                continue;
            }
            if (!inSingle && !inDouble && ch == ';')
            {
                var statement = builder.ToString().Trim();
                if (statement.Length > 0)
                {
                    statements.Add(statement);
                }
                builder.Clear();
                continue;
            }
            builder.Append(ch);
        }

        var trailing = builder.ToString().Trim();
        if (trailing.Length > 0)
        {
            statements.Add(trailing);
        }

        return statements;
    }

    private IReadOnlyList<ResultSetSummary> ExecuteQueryMultiInternal(
        string sql,
        IReadOnlyList<ScratchBirdParameter> parameters,
        int commandTimeoutSeconds,
        int fetchSize)
    {
        var client = EnsureConnectedClient();
        var timeoutMs = commandTimeoutSeconds > 0 ? checked(commandTimeoutSeconds * 1000) : 0;
        var maxRows = fetchSize > 0 ? fetchSize : _config.DefaultFetchSize;
        return client.ExecuteQueryMulti(sql, parameters, timeoutMs, maxRows);
    }

    private static TelemetryOptions BuildTelemetryOptions(ScratchBirdConfig config)
    {
        return new TelemetryOptions(
            EnableTracing: config.TelemetryEnableTracing,
            EnableMetrics: config.TelemetryEnableMetrics,
            EnableSlowOperationLog: config.TelemetryEnableSlowOperationLog,
            SlowOperationThresholdMs: config.TelemetrySlowOperationThresholdMs,
            SlowOperationMaxEntries: config.TelemetrySlowOperationMaxEntries,
            SampleRate: config.TelemetrySampleRate,
            SanitizeStatements: config.TelemetrySanitizeStatements);
    }

    private static CircuitBreakerOptions BuildCircuitBreakerOptions(ScratchBirdConfig config)
    {
        return new CircuitBreakerOptions(
            FailureThreshold: config.CircuitBreakerFailureThreshold,
            RecoveryTimeoutMs: config.CircuitBreakerRecoveryTimeoutMs,
            SuccessThreshold: config.CircuitBreakerSuccessThreshold,
            HalfOpenMaxRequests: config.CircuitBreakerHalfOpenMaxRequests);
    }

    private static IReadOnlyList<ScratchBirdParameter> NormalizeParameterList(IReadOnlyList<ScratchBirdParameter>? parameters)
    {
        return parameters ?? Array.Empty<ScratchBirdParameter>();
    }
}
