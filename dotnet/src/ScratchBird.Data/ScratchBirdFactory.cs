using System.Data.Common;

namespace ScratchBird.Data;

public sealed class ScratchBirdFactory : DbProviderFactory
{
    public static readonly ScratchBirdFactory Instance = new();

    public override DbConnection CreateConnection() => new ScratchBirdConnection();
    public override DbCommand CreateCommand() => new ScratchBirdCommand();
    public override DbParameter CreateParameter() => new ScratchBirdParameter();
}
