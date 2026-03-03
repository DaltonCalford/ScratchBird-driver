// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data;
using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdCommand : DbCommand
{
    private string _commandText = string.Empty;
    private int _commandTimeout = 30;
    private CommandType _commandType = CommandType.Text;
    private bool _designTimeVisible;
    private UpdateRowSource _updatedRowSource = UpdateRowSource.Both;
    private ScratchBirdConnection? _connection;
    private ScratchBirdTransaction? _transaction;
    private int _fetchSize;
    private readonly ScratchBirdParameterCollection _parameters = new();
    private NormalizedQuery? _preparedQuery;

    public ScratchBirdCommand() { }

    public ScratchBirdCommand(string commandText)
    {
        _commandText = commandText;
    }

    public ScratchBirdCommand(string commandText, ScratchBirdConnection connection)
    {
        _commandText = commandText;
        _connection = connection;
    }

    public ScratchBirdCommand(string commandText, ScratchBirdConnection connection, ScratchBirdTransaction transaction)
    {
        _commandText = commandText;
        _connection = connection;
        _transaction = transaction;
    }

    public override string CommandText
    {
        get => _commandText;
        set
        {
            _commandText = value ?? string.Empty;
            _preparedQuery = null;
        }
    }

    public override int CommandTimeout
    {
        get => _commandTimeout;
        set
        {
            if (value < 0)
            {
                throw new ArgumentOutOfRangeException(nameof(value), "CommandTimeout must be non-negative");
            }

            _commandTimeout = value;
        }
    }

    public override CommandType CommandType
    {
        get => _commandType;
        set
        {
            if (value != CommandType.Text)
            {
                throw new NotSupportedException("Only CommandType.Text is supported");
            }
            _commandType = value;
        }
    }

    public override bool DesignTimeVisible
    {
        get => _designTimeVisible;
        set => _designTimeVisible = value;
    }

    public override UpdateRowSource UpdatedRowSource
    {
        get => _updatedRowSource;
        set => _updatedRowSource = value;
    }

    public int FetchSize
    {
        get => _fetchSize;
        set => _fetchSize = Math.Max(0, value);
    }

    public new ScratchBirdConnection? Connection
    {
        get => _connection;
        set => _connection = value;
    }

    protected override DbConnection? DbConnection
    {
        get => _connection;
        set => _connection = value as ScratchBirdConnection;
    }

    public new ScratchBirdTransaction? Transaction
    {
        get => _transaction;
        set => _transaction = value;
    }

    protected override DbTransaction? DbTransaction
    {
        get => _transaction;
        set => _transaction = value as ScratchBirdTransaction;
    }

    public new ScratchBirdParameterCollection Parameters => _parameters;

    protected override DbParameterCollection DbParameterCollection => _parameters;

    public override void Prepare()
    {
        if (_commandType != CommandType.Text)
        {
            throw new NotSupportedException("Prepare only supports CommandType.Text");
        }
        ValidateCommandExecutionState();

        _preparedQuery = NormalizeParameters();
    }

    public override int ExecuteNonQuery()
    {
        return ExecuteNonQueryCore();
    }

    private int ExecuteNonQueryCore()
    {
        using var reader = ExecuteReader(CommandBehavior.SingleResult);
        while (reader.Read())
        {
        }
        return reader.RecordsAffected;
    }

    public override async Task<int> ExecuteNonQueryAsync(CancellationToken cancellationToken)
    {
        if (cancellationToken.IsCancellationRequested)
        {
            throw new OperationCanceledException(cancellationToken);
        }

        using var cancellation = cancellationToken.Register(Cancel);
        try
        {
            return await Task.Run(ExecuteNonQuery, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                throw new OperationCanceledException(cancellationToken);
            }
            throw;
        }
    }

    public override object? ExecuteScalar()
    {
        using var reader = ExecuteReader(CommandBehavior.SingleResult);
        object? first = null;
        if (reader.Read())
        {
            first = reader.GetValue(0);
        }

        while (reader.Read())
        {
        }

        return first;
    }

    public override async Task<object?> ExecuteScalarAsync(CancellationToken cancellationToken)
    {
        if (cancellationToken.IsCancellationRequested)
        {
            throw new OperationCanceledException(cancellationToken);
        }

        using var cancellation = cancellationToken.Register(Cancel);
        try
        {
            return await Task.Run(ExecuteScalar, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                throw new OperationCanceledException(cancellationToken);
            }
            throw;
        }
    }

    public new ScratchBirdDataReader ExecuteReader()
    {
        return (ScratchBirdDataReader)ExecuteDbDataReader(CommandBehavior.Default);
    }

    public new ScratchBirdDataReader ExecuteReader(CommandBehavior behavior)
    {
        return (ScratchBirdDataReader)ExecuteDbDataReader(behavior);
    }

    protected override DbDataReader ExecuteDbDataReader(CommandBehavior behavior)
    {
        ValidateCommandExecutionState();

        var connection = _connection!;
        var client = connection.GetConnectedClient();
        var normalized = NormalizeParameters();
        if (_preparedQuery == null
            || !string.Equals(_preparedQuery.Sql, normalized.Sql, StringComparison.Ordinal)
            || _preparedQuery.Parameters.Count != normalized.Parameters.Count)
        {
            _preparedQuery = normalized;
        }
        var timeoutMs = _commandTimeout > 0 ? _commandTimeout * 1000 : 0;
        var maxRows = _fetchSize > 0 ? _fetchSize : connection.Config.DefaultFetchSize;
        var stream = client.ExecuteQuery(normalized.Sql, normalized.Parameters, timeoutMs, maxRows);
        return new ScratchBirdDataReader(stream, behavior, connection);
    }

    private NormalizedQuery NormalizeParameters()
    {
        return SqlHelpers.Normalize(_commandText, _parameters.Cast<ScratchBirdParameter>().ToList());
    }

    protected override async Task<DbDataReader> ExecuteDbDataReaderAsync(CommandBehavior behavior, CancellationToken cancellationToken)
    {
        if (cancellationToken.IsCancellationRequested)
        {
            throw new OperationCanceledException(cancellationToken);
        }

        using var cancellation = cancellationToken.Register(Cancel);
        try
        {
            return await Task.Run(() => ExecuteDbDataReader(behavior), cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                throw new OperationCanceledException(cancellationToken);
            }
            throw;
        }
    }

    public override void Cancel()
    {
        if (_connection == null || _connection.State != ConnectionState.Open)
        {
            return;
        }

        try
        {
            var client = _connection.GetConnectedClient();
            client.Cancel();

            // A canceled stream can leave unread protocol frames; force reconnect on next use.
            client.Close();
        }
        catch
        {
            // best effort; caller requested cancellation and does not need transport details here
        }
    }

    protected override DbParameter CreateDbParameter()
    {
        return new ScratchBirdParameter();
    }

    public new ScratchBirdParameter CreateParameter()
    {
        return new ScratchBirdParameter();
    }

    private void ValidateCommandExecutionState()
    {
        if (_connection == null || _connection.State != ConnectionState.Open)
        {
            throw new InvalidOperationException("Connection must be open");
        }

        if (string.IsNullOrWhiteSpace(_commandText))
        {
            throw new InvalidOperationException("CommandText must be set");
        }

        if (_transaction == null)
        {
            if (_connection.HasActiveTransaction)
            {
                throw new InvalidOperationException("Command requires an explicit Transaction when the connection has an active transaction");
            }

            return;
        }

        if (!_transaction.BelongsTo(_connection))
        {
            throw new InvalidOperationException("Transaction is not associated with this command's connection");
        }

        if (_transaction.IsDisposed)
        {
            throw new InvalidOperationException("Transaction is disposed");
        }

        if (_transaction.IsCompleted)
        {
            throw new InvalidOperationException("Transaction is already completed");
        }

        if (!_connection.IsActiveTransaction(_transaction))
        {
            throw new InvalidOperationException("Transaction is not active on this connection");
        }
    }

}
