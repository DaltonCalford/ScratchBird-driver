// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using System.Reflection;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class PipelineSurfaceTests
{
    [Fact]
    public void PipelineMonitor_RejectsWhenAtCapacity()
    {
        var monitor = new PipelineMonitor(new PipelineOptions(MaxInFlight: 1));

        Assert.True(monitor.TryAcquire());
        Assert.False(monitor.TryAcquire());

        var full = monitor.Snapshot();
        Assert.True(full.Enabled);
        Assert.Equal(1, full.MaxInFlight);
        Assert.Equal(1, full.InFlight);
        Assert.Equal(1, full.TotalAccepted);
        Assert.Equal(1, full.TotalRejected);

        monitor.Release(success: true);

        var released = monitor.Snapshot();
        Assert.Equal(0, released.InFlight);
        Assert.Equal(1, released.TotalCompleted);
        Assert.Equal(0, released.TotalFailed);
    }

    [Fact]
    public void PipelineMonitor_TracksFailedOperations()
    {
        var monitor = new PipelineMonitor(new PipelineOptions(MaxInFlight: 2));

        Assert.True(monitor.TryAcquire());
        monitor.Release(success: false);

        var snapshot = monitor.Snapshot();
        Assert.Equal(1, snapshot.TotalCompleted);
        Assert.Equal(1, snapshot.TotalFailed);
    }

    [Fact]
    public void ConnectionSurface_ExposesPipelineSummary()
    {
        using var connection = new ScratchBirdConnection(
            "Host=localhost;Port=3092;Database=main;pipeline_max_in_flight=7");

        var summary = connection.GetPipelineSummary();
        Assert.True(summary.Enabled);
        Assert.Equal(7, summary.MaxInFlight);
        Assert.Equal(0, summary.InFlight);
    }

    [Fact]
    public void ConnectionOperations_AreRejectedWhenPipelineIsSaturated()
    {
        using var connection = new ScratchBirdConnection(
            "Host=127.0.0.1;Port=65535;Database=main;pipeline_max_in_flight=1");

        var monitor = GetPrivateField<PipelineMonitor>(connection, "_pipelineMonitor");
        Assert.True(monitor.TryAcquire());

        var ex = Assert.Throws<ScratchBirdLimitException>(() => connection.Open());
        Assert.Equal("54000", ex.SqlState);

        var summary = connection.GetPipelineSummary();
        Assert.Equal(1, summary.InFlight);
        Assert.Equal(1, summary.TotalRejected);

        monitor.Release(success: true);
    }

    private static T GetPrivateField<T>(object target, string fieldName)
        where T : class
    {
        var field = target.GetType().GetField(fieldName, BindingFlags.Instance | BindingFlags.NonPublic);
        Assert.NotNull(field);
        var value = field!.GetValue(target);
        Assert.IsType<T>(value);
        return (T)value!;
    }
}
