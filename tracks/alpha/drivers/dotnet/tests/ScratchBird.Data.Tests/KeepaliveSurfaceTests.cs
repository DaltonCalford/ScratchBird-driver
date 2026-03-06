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

public class KeepaliveSurfaceTests
{
    [Fact]
    public void KeepaliveMonitor_ValidatesAfterIdleThreshold()
    {
        var now = DateTimeOffset.UtcNow;
        var monitor = new KeepaliveMonitor(
            new KeepaliveOptions(IntervalMs: 1, MaxIdleBeforeCheckMs: 10, ValidationTimeoutMs: 50),
            () => now);

        now = now.AddMilliseconds(50);
        var validated = monitor.ValidateIfNeeded(() => true);

        Assert.True(validated);
        var summary = monitor.Snapshot();
        Assert.True(summary.Enabled);
        Assert.Equal(1, summary.ValidationAttempts);
        Assert.Equal(1, summary.ValidationSuccesses);
        Assert.Equal(0, summary.ValidationFailures);
        Assert.NotNull(summary.LastValidationUtc);
    }

    [Fact]
    public void KeepaliveMonitor_RecordsFailedValidation()
    {
        var now = DateTimeOffset.UtcNow;
        var monitor = new KeepaliveMonitor(
            new KeepaliveOptions(IntervalMs: 1, MaxIdleBeforeCheckMs: 5, ValidationTimeoutMs: 50),
            () => now);

        now = now.AddMilliseconds(20);
        var validated = monitor.ValidateIfNeeded(() => false);

        Assert.False(validated);
        var summary = monitor.Snapshot();
        Assert.Equal(1, summary.ValidationAttempts);
        Assert.Equal(0, summary.ValidationSuccesses);
        Assert.Equal(1, summary.ValidationFailures);
    }

    [Fact]
    public void ConnectionSurface_ExposesKeepaliveSummary()
    {
        using var connection = new ScratchBirdConnection(
            "Host=localhost;Port=3092;Database=main;keepalive_interval_ms=1234;keepalive_max_idle_before_check_ms=4321;keepalive_validation_timeout_ms=210");

        var summary = connection.GetKeepaliveSummary();
        Assert.True(summary.Enabled);
        Assert.Equal(1234, summary.IntervalMs);
        Assert.Equal(4321, summary.MaxIdleBeforeCheckMs);
        Assert.Equal(210, summary.ValidationTimeoutMs);
    }
}
