using System.Data;
using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdTransaction : DbTransaction
{
    private readonly ScratchBirdConnection _connection;
    private readonly IsolationLevel _isolationLevel;
    private bool _completed;

    internal ScratchBirdTransaction(ScratchBirdConnection connection, IsolationLevel isolationLevel)
    {
        _connection = connection;
        _isolationLevel = isolationLevel;
    }

    public override IsolationLevel IsolationLevel => _isolationLevel;

    protected override DbConnection DbConnection => _connection;

    public override void Commit()
    {
        if (_completed)
        {
            return;
        }
        _connection.Client.Commit();
        _completed = true;
    }

    public override void Rollback()
    {
        if (_completed)
        {
            return;
        }
        _connection.Client.Rollback();
        _completed = true;
    }
}
