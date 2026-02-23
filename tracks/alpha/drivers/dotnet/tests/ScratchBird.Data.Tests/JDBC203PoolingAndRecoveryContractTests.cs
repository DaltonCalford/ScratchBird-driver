// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class JDBC203PoolingAndRecoveryContractTests
{
    private const int ScenarioCWorkers = 10;

    [Fact]
    public async Task ScenarioA_BorrowReuseAfterExplicitCancel()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        var cancelSql = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_CANCEL_SQL");
        if (string.IsNullOrWhiteSpace(dsn) || string.IsNullOrWhiteSpace(cancelSql))
        {
            return;
        }

        var poolingDsn = AddPoolingFlags(dsn, maxPoolSize: 4, minPoolSize: 0, connectionLifetime: 30);
        var beforeStats = GetPoolStats(poolingDsn);

        using (var conn = new ScratchBirdConnection(poolingDsn))
        {
            conn.Open();
            using var statement = conn.CreateCommand();
            statement.CommandText = cancelSql;

            var executeTask = statement.ExecuteNonQueryAsync();
            Thread.Sleep(150);
            statement.Cancel();

            await Assert.ThrowsAnyAsync<Exception>(async () => await executeTask.ConfigureAwait(false));
        }

        using (var verify = new ScratchBirdConnection(poolingDsn))
        {
            verify.Open();
            using var statement = verify.CreateCommand();
            statement.CommandText = "SELECT 1";
            var result = Convert.ToInt32(statement.ExecuteScalar());
            Assert.Equal(1, result);
        }

        var afterStats = GetPoolStats(poolingDsn);
        Assert.NotNull(beforeStats);
        Assert.NotNull(afterStats);
        Assert.True(afterStats.Value.Borrowed >= 1);
        Assert.True(afterStats.Value.Returned >= beforeStats.Value.Returned);
    }

    [Fact]
    public void ScenarioB_TimeoutCancellationReuse()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        var cancelSql = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_CANCEL_SQL");
        if (string.IsNullOrWhiteSpace(dsn) || string.IsNullOrWhiteSpace(cancelSql))
        {
            return;
        }

        var poolingDsn = AddPoolingFlags(dsn, maxPoolSize: 4, minPoolSize: 0, connectionLifetime: 30);

        using (var conn = new ScratchBirdConnection(poolingDsn))
        {
            conn.Open();
            using var statement = conn.CreateCommand();
            statement.CommandText = cancelSql;
            statement.CommandTimeout = 1;
            Assert.ThrowsAny<Exception>(() => statement.ExecuteNonQuery());
        }

        using (var verify = new ScratchBirdConnection(poolingDsn))
        {
            verify.Open();
            using var statement = verify.CreateCommand();
            statement.CommandText = "SELECT 1";
            var result = Convert.ToInt32(statement.ExecuteScalar());
            Assert.Equal(1, result);
        }
    }

    [Fact]
    public async Task ScenarioC_ConcurrentPoolStress10Workers()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        if (string.IsNullOrWhiteSpace(dsn))
        {
            return;
        }

        var poolingDsn = AddPoolingFlags(dsn, maxPoolSize: 3, minPoolSize: 0, connectionLifetime: 20);
        var tasks = Enumerable.Range(0, ScenarioCWorkers).Select(_ => Task.Run(() =>
        {
            using var conn = new ScratchBirdConnection(poolingDsn);
            conn.Open();
            using var statement = conn.CreateCommand();
            statement.CommandText = "SELECT 1";
            var result = Convert.ToInt32(statement.ExecuteScalar());
            return result == 1;
        })).ToList();

        var results = await Task.WhenAll(tasks);
        Assert.All(results, Assert.True);

        var afterStats = GetPoolStats(poolingDsn);
        Assert.NotNull(afterStats);
        Assert.True(afterStats.Value.Borrowed <= 3);
        Assert.True(afterStats.Value.BorrowAttempts >= 10);
    }

    [Fact]
    public void ScenarioD_ReconnectRecoveryAfterFailure()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        var cancelSql = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_CANCEL_SQL");
        if (string.IsNullOrWhiteSpace(dsn) || string.IsNullOrWhiteSpace(cancelSql))
        {
            return;
        }

        var poolingDsn = AddPoolingFlags(dsn, maxPoolSize: 2, minPoolSize: 0, connectionLifetime: 30);

        for (var iteration = 0; iteration < 2; iteration++)
        {
            using (var conn = new ScratchBirdConnection(poolingDsn))
            {
                conn.Open();
                using var statement = conn.CreateCommand();
                statement.CommandText = cancelSql;
                statement.CommandTimeout = 1;
                Assert.ThrowsAny<Exception>(() => statement.ExecuteNonQuery());
            }
        }

        using var verify = new ScratchBirdConnection(poolingDsn);
        verify.Open();
        using var verifyStatement = verify.CreateCommand();
        verifyStatement.CommandText = "SELECT 1";
        var result = Convert.ToInt32(verifyStatement.ExecuteScalar());
        Assert.Equal(1, result);
    }

    [Fact]
    public void ScenarioE_MetadataAndStreamReuseAfterRecovery()
    {
        var dsn = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_URL");
        var cancelSql = Environment.GetEnvironmentVariable("SCRATCHBIRD_DOTNET_CANCEL_SQL");
        if (string.IsNullOrWhiteSpace(dsn) || string.IsNullOrWhiteSpace(cancelSql))
        {
            return;
        }

        var table = $"dotnet203_contract_{Guid.NewGuid():N}";
        var payloadText = $"payload-{DateTime.UtcNow:O}";
        var poolingDsn = AddPoolingFlags(dsn, maxPoolSize: 4, minPoolSize: 0, connectionLifetime: 30);

        using (var conn = new ScratchBirdConnection(poolingDsn))
        {
            conn.Open();
            using var ddl = conn.CreateCommand();
            ddl.CommandText = $"CREATE TABLE {table} (id INTEGER, note TEXT)";
            ddl.ExecuteNonQuery();

            using var insert = conn.CreateCommand();
            insert.CommandText = $"INSERT INTO {table} (id, note) VALUES (?, ?)";
            insert.Parameters.Add(new ScratchBirdParameter("", 1));
            insert.Parameters.Add(new ScratchBirdParameter("", payloadText));
            insert.ExecuteNonQuery();
        }

        using (var conn = new ScratchBirdConnection(poolingDsn))
        {
            conn.Open();

            using var cancelCommand = conn.CreateCommand();
            cancelCommand.CommandText = cancelSql;
            cancelCommand.CommandTimeout = 1;
            Assert.ThrowsAny<Exception>(() => cancelCommand.ExecuteNonQuery());

            using var metadata = conn.GetSchema("Columns");
            Assert.Contains(metadata.Rows.Cast<System.Data.DataRow>(), r =>
                string.Equals(r["TABLE_NAME"]?.ToString(), table, StringComparison.OrdinalIgnoreCase));

            using var select = conn.CreateCommand();
            select.CommandText = $"SELECT note FROM {table} WHERE id = ?";
            select.Parameters.Add(new ScratchBirdParameter("", 1));
            using var reader = select.ExecuteReader();
            Assert.True(reader.Read());
            Assert.Equal(payloadText, reader.GetString(0));
        }

        using (var cleanup = new ScratchBirdConnection(poolingDsn))
        {
            cleanup.Open();
            using var drop = cleanup.CreateCommand();
            drop.CommandText = $"DROP TABLE {table}";
            drop.ExecuteNonQuery();
        }
    }

    private static string AddPoolingFlags(
        string dsn,
        int maxPoolSize,
        int connectionLifetime,
        int minPoolSize)
    {
        if (dsn.Contains("://", StringComparison.OrdinalIgnoreCase))
        {
            return
                $"{dsn}{(dsn.Contains("?", StringComparison.OrdinalIgnoreCase) ? "&" : "?")}Pooling=true&MaxPoolSize={maxPoolSize}&ConnectionLifetime={connectionLifetime}&MinPoolSize={minPoolSize}";
        }

        return
            $"{dsn};Pooling=true;MaxPoolSize={maxPoolSize};ConnectionLifetime={connectionLifetime};MinPoolSize={minPoolSize}";
    }

    private static ProtocolClientPool.PoolStats? GetPoolStats(string dsn)
    {
        var config = ScratchBirdConfig.FromConnectionString(dsn);
        return ProtocolClientPool.GetStats(config);
    }
}
