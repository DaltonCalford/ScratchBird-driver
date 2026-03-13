// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
namespace ScratchBird.Data;

internal readonly record struct PipelineOptions(int MaxInFlight)
{
    public static PipelineOptions Default { get; } = new(MaxInFlight: 100);
    public bool Enabled => MaxInFlight > 0;

    public PipelineOptions Normalize()
    {
        return new PipelineOptions(Math.Max(0, MaxInFlight));
    }
}

internal readonly record struct PipelineSnapshot(
    bool Enabled,
    int MaxInFlight,
    int InFlight,
    long TotalAccepted,
    long TotalRejected,
    long TotalCompleted,
    long TotalFailed);

internal sealed class PipelineMonitor
{
    private readonly PipelineOptions _options;
    private readonly object _sync = new();
    private int _inFlight;
    private long _totalAccepted;
    private long _totalRejected;
    private long _totalCompleted;
    private long _totalFailed;

    public PipelineMonitor()
        : this(PipelineOptions.Default)
    {
    }

    public PipelineMonitor(PipelineOptions options)
    {
        _options = options.Normalize();
    }

    public bool TryAcquire()
    {
        if (!_options.Enabled)
        {
            return true;
        }

        lock (_sync)
        {
            if (_inFlight >= _options.MaxInFlight)
            {
                _totalRejected++;
                return false;
            }

            _inFlight++;
            _totalAccepted++;
            return true;
        }
    }

    public void Release(bool success)
    {
        if (!_options.Enabled)
        {
            return;
        }

        lock (_sync)
        {
            if (_inFlight > 0)
            {
                _inFlight--;
            }

            _totalCompleted++;
            if (!success)
            {
                _totalFailed++;
            }
        }
    }

    public PipelineSnapshot Snapshot()
    {
        lock (_sync)
        {
            return new PipelineSnapshot(
                Enabled: _options.Enabled,
                MaxInFlight: _options.MaxInFlight,
                InFlight: _inFlight,
                TotalAccepted: _totalAccepted,
                TotalRejected: _totalRejected,
                TotalCompleted: _totalCompleted,
                TotalFailed: _totalFailed);
        }
    }
}
