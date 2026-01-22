using System;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class IntegrationTests
{
    [Fact]
    public void ConnectAndSelect()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }

        using var conn = new ScratchBirdConnection(dsn);
        conn.Open();

        using var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT 1";
        var result = cmd.ExecuteScalar();

        Assert.NotNull(result);
    }
}
