using System;
using System.Threading.Tasks;
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

    [Fact]
    public void PrepareBindQuery()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }

        using var conn = new ScratchBirdConnection(dsn);
        conn.Open();

        using var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT ?::INTEGER";
        cmd.Parameters.Add(new ScratchBirdParameter("", 42));
        var result = cmd.ExecuteScalar();

        Assert.Equal(42, Convert.ToInt32(result));
    }

    [Fact]
    public void TypesFixtureQuery()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }

        using var conn = new ScratchBirdConnection(dsn);
        conn.Open();

        using var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT * FROM sb_conformance.type_coverage";
        using var reader = cmd.ExecuteReader();

        Assert.True(reader.Read());
    }

    [Fact]
    public async Task CancelQuery()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }
        var cancelSql = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_CANCEL_SQL");
        if (string.IsNullOrWhiteSpace(cancelSql))
        {
            return;
        }

        using var conn = new ScratchBirdConnection(dsn);
        conn.Open();

        using var cmd = conn.CreateCommand();
        cmd.CommandText = cancelSql;
        var task = cmd.ExecuteNonQueryAsync();
        await Task.Delay(200);
        cmd.Cancel();
        await Assert.ThrowsAnyAsync<Exception>(async () => await task);
    }
}
