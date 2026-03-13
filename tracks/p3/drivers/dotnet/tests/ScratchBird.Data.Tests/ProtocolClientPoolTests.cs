// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class ProtocolClientPoolTests
{
    [Fact]
    public void BorrowOrCreate_WhenPoolExhaustedAndAcquireTimeoutZero_UsesUnpooledFallback()
    {
        var unique = Guid.NewGuid().ToString("N");
        var config = ScratchBirdConfig.FromConnectionString(
            $"Host=127.0.0.1;Port=13092;Database=pool_{unique};Username=user_{unique};Password=secret;Pooling=true;MinPoolSize=0;MaxPoolSize=1;ConnectionLifetime=30;PoolAcquireTimeoutMs=0");

        var pooledClient = ProtocolClientPool.BorrowOrCreate(config, out var pooledLease);
        var fallbackClient = ProtocolClientPool.BorrowOrCreate(config, out var fallbackLease);

        Assert.NotSame(pooledClient, fallbackClient);
        var stats = ProtocolClientPool.GetStats(config);
        Assert.NotNull(stats);
        Assert.Equal(2, stats!.Value.BorrowAttempts);
        Assert.Equal(1, stats.Value.Borrowed);
        Assert.Equal(1, stats.Value.ActiveCount);

        fallbackLease.Dispose();
        pooledLease.Dispose();
    }
}
