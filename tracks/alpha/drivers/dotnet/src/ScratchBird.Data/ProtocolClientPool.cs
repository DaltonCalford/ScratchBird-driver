// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System;
using System.Collections.Concurrent;
using System.Threading;

namespace ScratchBird.Data;

internal sealed class ProtocolClientPool
{
    private sealed class PooledClient
    {
        public PooledClient(ProtocolClient protocol, TimeSpan maxAge)
        {
            Protocol = protocol;
            CreatedUtc = DateTimeOffset.UtcNow;
            LastReturnedUtc = CreatedUtc;
            MaxAge = maxAge;
        }

        public ProtocolClient Protocol { get; }
        public DateTimeOffset CreatedUtc { get; }
        public DateTimeOffset LastReturnedUtc { get; set; }
        public TimeSpan MaxAge { get; }

        public bool Expired => MaxAge > TimeSpan.Zero && (DateTimeOffset.UtcNow - CreatedUtc) > MaxAge;
    }

    private sealed class ClientPool
    {
        private readonly ConcurrentQueue<PooledClient> _idle = new();

        public int MaxSize;
        public int ActiveCount;

        public bool TryTake(out ProtocolClient protocol)
        {
            while (_idle.TryDequeue(out var item))
            {
                item.LastReturnedUtc = DateTimeOffset.UtcNow;

                if (item.Expired || !item.Protocol.Connected)
                {
                    item.Protocol.Close();
                    continue;
                }

                protocol = item.Protocol;
                return true;
            }

            protocol = default!;
            return false;
        }

        public bool TryReturn(ProtocolClient protocol, TimeSpan maxAge)
        {
            if (_idle.Count >= MaxSize)
            {
                return false;
            }

            _idle.Enqueue(new PooledClient(protocol, maxAge));
            return true;
        }
    }

    internal sealed class Lease : IDisposable
    {
        private readonly ProtocolClient _client;
        private readonly ScratchBirdConfig _config;
        private bool _disposed;

        public Lease(ProtocolClient client, ScratchBirdConfig config)
        {
            _client = client;
            _config = config;
        }

        public ProtocolClient Client => _client;

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            _disposed = true;
            ProtocolClientPool.Return(_config, _client);
            GC.SuppressFinalize(this);
        }
    }

    private static readonly ConcurrentDictionary<string, ClientPool> Pools = new();

    public static ProtocolClient BorrowOrCreate(ScratchBirdConfig config, out Lease lease)
    {
        if (!config.Pooling)
        {
            var client = new ProtocolClient();
            lease = new Lease(client, config);
            return client;
        }

        var key = BuildPoolKey(config);
        var pool = Pools.GetOrAdd(key, _ => new ClientPool { MaxSize = Math.Max(1, config.MaxPoolSize) });

        if (pool.TryTake(out var pooledClient))
        {
            Interlocked.Increment(ref pool.ActiveCount);
            lease = new Lease(pooledClient, config);
            return pooledClient;
        }

        var fresh = new ProtocolClient();
        Interlocked.Increment(ref pool.ActiveCount);
        lease = new Lease(fresh, config);
        return fresh;
    }

    public static void Return(ScratchBirdConfig config, ProtocolClient client)
    {
        if (!config.Pooling || !client.Connected)
        {
            client.Close();
            return;
        }

        var key = BuildPoolKey(config);
        var pool = Pools.GetOrAdd(key, _ => new ClientPool { MaxSize = Math.Max(1, config.MaxPoolSize) });

        var maxAge = TimeSpan.FromSeconds(Math.Max(0, config.ConnectionLifetime));
        if (!pool.TryReturn(client, maxAge))
        {
            client.Close();
        }

        if (pool.ActiveCount > 0)
        {
            Interlocked.Decrement(ref pool.ActiveCount);
        }
    }

    private static string BuildPoolKey(ScratchBirdConfig config)
    {
        return $"{config.FrontDoorMode}|{config.Protocol}|{config.Host}:{config.Port}|{config.Database}|{config.Username}|{config.Schema}|{config.ManagerConnectionProfile}|{config.ManagerClientIntent}";
    }
}
