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

public class SubscriptionSurfaceTests
{
    [Fact]
    public void NormalizeNotificationChannel_TrimmedValueIsReturned()
    {
        var normalized = ScratchBirdConnection.NormalizeNotificationChannel("  channel.events  ");
        Assert.Equal("channel.events", normalized);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("chan\0nel")]
    public void NormalizeNotificationChannel_InvalidInputThrows(string? channel)
    {
        Assert.Throws<ArgumentException>(() => ScratchBirdConnection.NormalizeNotificationChannel(channel));
    }

    [Fact]
    public void Listen_WhenClosedRecordsFailureTelemetry()
    {
        using var connection = new ScratchBirdConnection();

        Assert.Throws<InvalidOperationException>(() => connection.Listen("alerts"));

        var summary = connection.GetTelemetrySummary();
        var operation = Assert.Single(summary.Operations, value => value.Operation == "Connection.Subscribe");
        Assert.Equal(1, operation.Invocations);
        Assert.Equal(0, operation.Successes);
        Assert.Equal(1, operation.Failures);
    }

    [Fact]
    public void Unlisten_WhenClosedRecordsFailureTelemetry()
    {
        using var connection = new ScratchBirdConnection();

        Assert.Throws<InvalidOperationException>(() => connection.Unlisten("alerts"));

        var summary = connection.GetTelemetrySummary();
        var operation = Assert.Single(summary.Operations, value => value.Operation == "Connection.Unsubscribe");
        Assert.Equal(1, operation.Invocations);
        Assert.Equal(0, operation.Successes);
        Assert.Equal(1, operation.Failures);
    }

    [Fact]
    public void BuildNotifyCommand_QuotesChannelAndPayload()
    {
        var sql = ScratchBirdConnection.BuildNotifyCommand(" chan\"nel ", "O'Reilly");
        Assert.Equal("NOTIFY \"chan\"\"nel\", 'O''Reilly'", sql);
    }

    [Fact]
    public void BuildNotifyCommand_RejectsPayloadWithNul()
    {
        Assert.Throws<ArgumentException>(() => ScratchBirdConnection.BuildNotifyCommand("alerts", "bad\0payload"));
    }

    [Fact]
    public void NotifyChannel_WhenClosedRecordsFailureTelemetry()
    {
        using var connection = new ScratchBirdConnection();

        Assert.Throws<InvalidOperationException>(() => connection.NotifyChannel("alerts"));

        var summary = connection.GetTelemetrySummary();
        var operation = Assert.Single(summary.Operations, value => value.Operation == "Connection.NotifyChannel");
        Assert.Equal(1, operation.Invocations);
        Assert.Equal(0, operation.Successes);
        Assert.Equal(1, operation.Failures);
    }

    [Fact]
    public void UnlistenAll_WhenClosedRecordsFailureTelemetry()
    {
        using var connection = new ScratchBirdConnection();

        Assert.Throws<InvalidOperationException>(() => connection.UnlistenAll());

        var summary = connection.GetTelemetrySummary();
        var operation = Assert.Single(summary.Operations, value => value.Operation == "Connection.UnlistenAll");
        Assert.Equal(1, operation.Invocations);
        Assert.Equal(0, operation.Successes);
        Assert.Equal(1, operation.Failures);
    }
}
