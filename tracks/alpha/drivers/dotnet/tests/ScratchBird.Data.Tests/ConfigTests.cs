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

public class ConfigTests
{
    [Fact]
    public void ParseUriDsn()
    {
        var cfg = ScratchBirdConfig.FromConnectionString("scratchbird://user:pass@localhost:3092/mydb?sslmode=require&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd");

        Assert.Equal("localhost", cfg.Host);
        Assert.Equal(3092, cfg.Port);
        Assert.Equal("mydb", cfg.Database);
        Assert.Equal("user", cfg.Username);
        Assert.Equal("pass", cfg.Password);
        Assert.Equal("require", cfg.SslMode);
        Assert.Equal(3000, cfg.ConnectTimeoutMs);
        Assert.Equal("app", cfg.ApplicationName);
        Assert.False(cfg.BinaryTransfer);
        Assert.Equal("zstd", cfg.Compression);
    }

    [Fact]
    public void ParseKeyValueDsn()
    {
        var cfg = ScratchBirdConfig.FromConnectionString("Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;Timeout=5;Socket_Timeout=7");

        Assert.Equal("server", cfg.Host);
        Assert.Equal(4000, cfg.Port);
        Assert.Equal("db", cfg.Database);
        Assert.Equal("me", cfg.Username);
        Assert.Equal("secret", cfg.Password);
        Assert.Equal("prefer", cfg.SslMode);
        Assert.Equal(5000, cfg.ConnectTimeoutMs);
        Assert.Equal(7000, cfg.SocketTimeoutMs);
    }
}
