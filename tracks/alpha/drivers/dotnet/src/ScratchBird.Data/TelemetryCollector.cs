// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Collections.Concurrent;
using System.Linq;

namespace ScratchBird.Data;

internal sealed class TelemetryCollector
{
    private sealed class OperationCounters
    {
        public long Invocations;
        public long Successes;
        public long Failures;
        public long TotalDurationMs;
        public long MaxDurationMs;
    }

    private readonly ConcurrentDictionary<string, OperationCounters> _operations = new(StringComparer.Ordinal);

    public void Record(string operation, TimeSpan duration, bool success)
    {
        if (string.IsNullOrWhiteSpace(operation))
        {
            return;
        }

        var counters = _operations.GetOrAdd(operation, _ => new OperationCounters());
        var durationMs = Math.Max(0, (long)duration.TotalMilliseconds);
        Interlocked.Increment(ref counters.Invocations);
        if (success)
        {
            Interlocked.Increment(ref counters.Successes);
        }
        else
        {
            Interlocked.Increment(ref counters.Failures);
        }

        Interlocked.Add(ref counters.TotalDurationMs, durationMs);
        UpdateMaxDuration(counters, durationMs);
    }

    public ConnectionTelemetrySummary Snapshot()
    {
        var operationSummaries = new List<OperationTelemetrySummary>(_operations.Count);
        foreach (var entry in _operations)
        {
            var counters = entry.Value;
            var invocations = Interlocked.Read(ref counters.Invocations);
            var successes = Interlocked.Read(ref counters.Successes);
            var failures = Interlocked.Read(ref counters.Failures);
            var totalDurationMs = Interlocked.Read(ref counters.TotalDurationMs);
            var maxDurationMs = Interlocked.Read(ref counters.MaxDurationMs);
            var average = invocations == 0 ? 0d : (double)totalDurationMs / invocations;
            operationSummaries.Add(new OperationTelemetrySummary(
                entry.Key,
                invocations,
                successes,
                failures,
                totalDurationMs,
                maxDurationMs,
                average));
        }

        operationSummaries.Sort((left, right) => string.Compare(left.Operation, right.Operation, StringComparison.Ordinal));
        var totalInvocations = operationSummaries.Sum(item => item.Invocations);
        var totalSuccesses = operationSummaries.Sum(item => item.Successes);
        var totalFailures = operationSummaries.Sum(item => item.Failures);
        return new ConnectionTelemetrySummary(
            DateTimeOffset.UtcNow,
            totalInvocations,
            totalSuccesses,
            totalFailures,
            operationSummaries);
    }

    public void Reset()
    {
        _operations.Clear();
    }

    private static void UpdateMaxDuration(OperationCounters counters, long candidate)
    {
        while (true)
        {
            var current = Interlocked.Read(ref counters.MaxDurationMs);
            if (candidate <= current)
            {
                return;
            }

            if (Interlocked.CompareExchange(ref counters.MaxDurationMs, candidate, current) == current)
            {
                return;
            }
        }
    }
}
