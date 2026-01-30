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
        set => _commandText = value ?? string.Empty;
    }

    public override int CommandTimeout
    {
        get => _commandTimeout;
        set => _commandTimeout = value;
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
    }

    public override int ExecuteNonQuery()
    {
        using var reader = ExecuteReader(CommandBehavior.SingleResult);
        while (reader.Read())
        {
        }
        return reader.RecordsAffected;
    }

    public override async Task<int> ExecuteNonQueryAsync(CancellationToken cancellationToken)
    {
        return await Task.Run(ExecuteNonQuery, cancellationToken);
    }

    public override object? ExecuteScalar()
    {
        using var reader = ExecuteReader(CommandBehavior.SingleRow);
        if (reader.Read())
        {
            return reader.GetValue(0);
        }
        return null;
    }

    public override async Task<object?> ExecuteScalarAsync(CancellationToken cancellationToken)
    {
        return await Task.Run(ExecuteScalar, cancellationToken);
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
        if (_connection == null || _connection.State != ConnectionState.Open)
        {
            throw new InvalidOperationException("Connection must be open");
        }

        var normalized = SqlHelpers.Normalize(_commandText, _parameters.Cast<ScratchBirdParameter>().ToList());
        var timeoutMs = _commandTimeout > 0 ? _commandTimeout * 1000 : 0;
        var maxRows = _fetchSize > 0 ? _fetchSize : _connection.Config.DefaultFetchSize;
        var stream = _connection.Client.ExecuteQuery(normalized.Sql, normalized.Parameters, timeoutMs, maxRows);
        return new ScratchBirdDataReader(stream, behavior, _connection);
    }

    protected override async Task<DbDataReader> ExecuteDbDataReaderAsync(CommandBehavior behavior, CancellationToken cancellationToken)
    {
        return await Task.Run(() => ExecuteDbDataReader(behavior), cancellationToken);
    }

    public override void Cancel()
    {
        _connection?.Client.Cancel();
    }

    protected override DbParameter CreateDbParameter()
    {
        return new ScratchBirdParameter();
    }

    public new ScratchBirdParameter CreateParameter()
    {
        return new ScratchBirdParameter();
    }

}
