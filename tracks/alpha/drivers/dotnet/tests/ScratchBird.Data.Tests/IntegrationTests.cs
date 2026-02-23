// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using System.Reflection;
using System.Threading;
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
        cmd.CommandText = "SELECT * FROM type_coverage";
        using var reader = cmd.ExecuteReader();

        Assert.True(reader.Read());
    }

    [Fact]
    public void ConnectionPoolingReusesProtocolClient()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }

        var poolingDsn = AddPoolingFlags(dsn);
        ProtocolClient? firstClient;

        using (var conn1 = new ScratchBirdConnection(poolingDsn))
        {
            conn1.Open();
            firstClient = GetClient(conn1);
        }

        using (var conn2 = new ScratchBirdConnection(poolingDsn))
        {
            conn2.Open();
            var secondClient = GetClient(conn2);
            Assert.NotNull(firstClient);
            Assert.Same(firstClient!, secondClient);
        }
    }

    [Fact]
    public void SavepointRollbackAndRelease()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }

        using var conn = new ScratchBirdConnection(dsn);
        conn.Open();

        using var tx = conn.BeginTransaction(System.Data.IsolationLevel.Serializable);
        tx.Save("odbc_pool_savepoint");
        tx.Rollback("odbc_pool_savepoint");
        tx.Release("odbc_pool_savepoint");
        tx.Rollback();
    }

    private static ProtocolClient? GetClient(ScratchBirdConnection connection)
    {
        var field = typeof(ScratchBirdConnection).GetField("_client", BindingFlags.NonPublic | BindingFlags.Instance);
        return field?.GetValue(connection) as ProtocolClient;
    }

    private static string AddPoolingFlags(string dsn)
    {
        if (dsn.Contains("://", StringComparison.OrdinalIgnoreCase))
        {
            return $"{dsn}{(dsn.Contains("?", StringComparison.OrdinalIgnoreCase) ? "&" : "?")}Pooling=true&MaxPoolSize=2&ConnectionLifetime=300";
        }
        if (dsn.EndsWith(';'))
        {
            return $"{dsn}Pooling=true;MaxPoolSize=2;ConnectionLifetime=300";
        }
        return $"{dsn};Pooling=true;MaxPoolSize=2;ConnectionLifetime=300";
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

    [Fact]
    public async Task CancelQueryAsyncViaTokenReleasesConnection()
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
        using var cts = new CancellationTokenSource(400);
        await Assert.ThrowsAnyAsync<Exception>(async () => await cmd.ExecuteNonQueryAsync(cts.Token));

        using var verify = conn.CreateCommand();
        verify.CommandText = "SELECT 1";
        var result = verify.ExecuteScalar();
        Assert.Equal(1, Convert.ToInt32(result));
    }
}
