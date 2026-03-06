// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class ConnectionStringBuilderSurfaceTests
{
    [Fact]
    public void PipelineProperties_HaveExpectedDefaults()
    {
        var builder = new ScratchBirdConnectionStringBuilder();

        Assert.Equal(100, builder.PipelineMaxInFlight);
        Assert.True(builder.PipelineAutoFlush);
        Assert.Equal(10, builder.PipelineAutoFlushThreshold);
        Assert.Equal(5000, builder.PipelineFlushTimeoutMs);
    }

    [Fact]
    public void PipelineProperties_RoundTripThroughConfigParsing()
    {
        var builder = new ScratchBirdConnectionStringBuilder
        {
            Host = "localhost",
            Port = 3092,
            Database = "main",
            PipelineMaxInFlight = 7,
            PipelineAutoFlush = false,
            PipelineAutoFlushThreshold = 3,
            PipelineFlushTimeoutMs = 750
        };

        var cfg = ScratchBirdConfig.FromConnectionString(builder.ConnectionString);
        Assert.Equal(7, cfg.PipelineMaxInFlight);
        Assert.False(cfg.PipelineAutoFlush);
        Assert.Equal(3, cfg.PipelineAutoFlushThreshold);
        Assert.Equal(750, cfg.PipelineFlushTimeoutMs);
    }
}
