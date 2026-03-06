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

public class TelemetrySurfaceTests
{
    [Fact]
    public void GetTelemetrySummary_WhenNoOperations_ReturnsEmptyTotals()
    {
        using var connection = new ScratchBirdConnection();

        var summary = connection.GetTelemetrySummary();

        Assert.Equal(0, summary.TotalInvocations);
        Assert.Equal(0, summary.TotalSuccesses);
        Assert.Equal(0, summary.TotalFailures);
        Assert.Empty(summary.Operations);
    }

    [Fact]
    public void RecordTelemetry_TracksOperationCounters()
    {
        using var connection = new ScratchBirdConnection();

        connection.RecordTelemetry("Command.ExecuteNonQuery", TimeSpan.FromMilliseconds(12), success: true);
        connection.RecordTelemetry("Command.ExecuteNonQuery", TimeSpan.FromMilliseconds(8), success: false);
        connection.RecordTelemetry("Connection.GetSchema", TimeSpan.FromMilliseconds(5), success: true);

        var summary = connection.GetTelemetrySummary();
        Assert.Equal(3, summary.TotalInvocations);
        Assert.Equal(2, summary.TotalSuccesses);
        Assert.Equal(1, summary.TotalFailures);

        var nonQuery = Assert.Single(summary.Operations, operation => operation.Operation == "Command.ExecuteNonQuery");
        Assert.Equal(2, nonQuery.Invocations);
        Assert.Equal(1, nonQuery.Successes);
        Assert.Equal(1, nonQuery.Failures);
        Assert.Equal(20, nonQuery.TotalDurationMs);
        Assert.Equal(12, nonQuery.MaxDurationMs);
        Assert.InRange(nonQuery.AverageDurationMs, 9.9d, 10.1d);
    }

    [Fact]
    public void CommandFailure_RecordsTelemetryOnConnection()
    {
        using var connection = new ScratchBirdConnection(
            "Host=localhost;Port=13092;Database=main;Username=sb_admin;Password=SbAdmin_Compat1!;Pooling=false");
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT 1";

        Assert.Throws<InvalidOperationException>(() => command.ExecuteNonQuery());

        var summary = connection.GetTelemetrySummary();
        var operation = Assert.Single(summary.Operations, value => value.Operation == "Command.ExecuteNonQuery");
        Assert.Equal(1, operation.Invocations);
        Assert.Equal(0, operation.Successes);
        Assert.Equal(1, operation.Failures);
    }

    [Fact]
    public void ResetTelemetry_ClearsAllCounters()
    {
        using var connection = new ScratchBirdConnection();
        connection.RecordTelemetry("Connection.QueryMulti", TimeSpan.FromMilliseconds(10), success: true);
        Assert.NotEmpty(connection.GetTelemetrySummary().Operations);

        connection.ResetTelemetry();
        var summary = connection.GetTelemetrySummary();

        Assert.Equal(0, summary.TotalInvocations);
        Assert.Empty(summary.Operations);
    }
}
