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
        public PooledClient(ProtocolClient client, DateTimeOffset createdUtc)
        {
            Client = client;
            CreatedUtc = createdUtc;
        }

        public ProtocolClient Client { get; }
        public DateTimeOffset CreatedUtc { get; }
    }

    internal sealed class ClientPool
    {
        private const int BorrowTimeoutMs = 250;
        private readonly ConcurrentQueue<PooledClient> _idle = new();
        private readonly ConcurrentDictionary<ProtocolClient, DateTimeOffset> _active = new();
        private readonly SemaphoreSlim _slots;

        public ClientPool(int maxSize)
        {
            MaxSize = Math.Max(1, maxSize);
            _slots = new SemaphoreSlim(MaxSize, MaxSize);
        }

        public int MaxSize { get; set; }
        public int MinSize { get; set; }

        public int ActiveCount => _active.Count;
        public int IdleCount => _idle.Count;

        public bool TryBorrow(TimeSpan maxAge, out ProtocolClient protocolClient)
        {
            protocolClient = default!;

            if (!TryAcquireSlot())
            {
                return false;
            }

            var now = DateTimeOffset.UtcNow;
            while (_idle.TryDequeue(out var pooled))
            {
                if (!pooled.Client.IsHealthy || IsExpired(pooled.CreatedUtc, now, maxAge))
                {
                    pooled.Client.Close();
                    continue;
                }

                if (_active.TryAdd(pooled.Client, pooled.CreatedUtc))
                {
                    protocolClient = pooled.Client;
                    return true;
                }

                pooled.Client.Close();
            }

            protocolClient = new ProtocolClient();
            _active.TryAdd(protocolClient, now);
            return true;
        }

        public void Return(ProtocolClient protocolClient, TimeSpan maxAge)
        {
            if (!_active.TryRemove(protocolClient, out var createdUtc))
            {
                protocolClient.Close();
                return;
            }

            if (protocolClient.IsHealthy && !IsExpired(createdUtc, DateTimeOffset.UtcNow, maxAge))
            {
                _idle.Enqueue(new PooledClient(protocolClient, createdUtc));
            }
            else
            {
                protocolClient.Close();
            }

            _slots.Release();
        }

        public void Reject(ProtocolClient protocolClient)
        {
            if (_active.TryRemove(protocolClient, out _))
            {
                protocolClient.Close();
                _slots.Release();
            }
            else
            {
                protocolClient.Close();
            }
        }

        private bool TryAcquireSlot()
        {
            if (_slots.Wait(0))
            {
                return true;
            }

            // Avoid indefinite block; fallback clients can still be created outside the pool.
            return _slots.Wait(BorrowTimeoutMs);
        }

        private static bool IsExpired(DateTimeOffset createdUtc, DateTimeOffset now, TimeSpan maxAge)
        {
            return maxAge > TimeSpan.Zero && (now - createdUtc) > maxAge;
        }
    }

    internal sealed class Lease : IDisposable
    {
        private readonly ProtocolClient _client;
        private readonly ScratchBirdConfig _config;
        private readonly ClientPool? _pool;
        private bool _disposed;

        internal Lease(ProtocolClient client, ScratchBirdConfig config, ClientPool? pool = null)
        {
            _client = client;
            _config = config;
            _pool = pool;
        }

        public ProtocolClient Client => _client;

        public void Dispose()
        {
            if (_disposed)
            {
                return;
            }

            _disposed = true;
            Return(_config, _client, _pool);
            GC.SuppressFinalize(this);
        }
    }

    private static readonly ConcurrentDictionary<string, ClientPool> Pools = new();

    internal static ProtocolClient BorrowOrCreate(ScratchBirdConfig config, out Lease lease)
    {
        if (!config.Pooling)
        {
            var client = new ProtocolClient();
            lease = new Lease(client, config);
            return client;
        }

        var key = BuildPoolKey(config);
        var pool = Pools.GetOrAdd(
            key,
            _ => new ClientPool(Math.Max(1, config.MaxPoolSize))
            {
                MinSize = Math.Max(0, config.MinPoolSize)
            });
        pool.MaxSize = Math.Max(1, config.MaxPoolSize);
        pool.MinSize = Math.Max(0, config.MinPoolSize);

        var maxAge = TimeSpan.FromSeconds(Math.Max(0, config.ConnectionLifetime));
        if (pool.TryBorrow(maxAge, out var protocolClient))
        {
            lease = new Lease(protocolClient, config, pool);
            return protocolClient;
        }

        // Fallback when pool is full: do not track these clients.
        var unpooledClient = new ProtocolClient();
        lease = new Lease(unpooledClient, config);
        return unpooledClient;
    }

    internal static void Return(ScratchBirdConfig config, ProtocolClient client, ClientPool? pool = null)
    {
        if (!config.Pooling || pool == null)
        {
            client.Close();
            return;
        }

        var maxAge = TimeSpan.FromSeconds(Math.Max(0, config.ConnectionLifetime));
        if (!client.IsHealthy)
        {
            pool.Reject(client);
            return;
        }

        pool.Return(client, maxAge);
    }

    private static string BuildPoolKey(ScratchBirdConfig config)
    {
        return $"{config.FrontDoorMode}|{config.Protocol}|{config.Host}:{config.Port}|{config.Database}|{config.Username}|{config.Schema}|{config.ManagerConnectionProfile}|{config.ManagerClientIntent}|{config.SslMode}|{config.SslRootCert}|{config.SslCert}|{config.ManagerAuthFastPath}|{config.ManagerClientFlags}|{config.MaxPoolSize}|{config.MinPoolSize}|{config.ConnectionLifetime}";
    }
}
