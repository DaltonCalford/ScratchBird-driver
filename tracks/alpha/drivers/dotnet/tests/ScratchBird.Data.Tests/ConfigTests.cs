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
        var cfg = ScratchBirdConfig.FromConnectionString("scratchbird://user:pass@localhost:3092/mydb?sslmode=require&allow_insecure=true&connect_timeout=3&application_name=app&binary_transfer=false&compression=zstd");

        Assert.Equal("localhost", cfg.Host);
        Assert.Equal(3092, cfg.Port);
        Assert.Equal("mydb", cfg.Database);
        Assert.Equal("user", cfg.Username);
        Assert.Equal("pass", cfg.Password);
        Assert.Equal("require", cfg.SslMode);
        Assert.True(cfg.AllowInsecureDisable);
        Assert.Equal(3000, cfg.ConnectTimeoutMs);
        Assert.Equal("app", cfg.ApplicationName);
        Assert.False(cfg.BinaryTransfer);
        Assert.Equal("zstd", cfg.Compression);
    }

    [Fact]
    public void ParseKeyValueDsn()
    {
        var cfg = ScratchBirdConfig.FromConnectionString("Host=server;Port=4000;Database=db;Username=me;Password=secret;SSL Mode=prefer;AllowInsecure=true;Timeout=5;Socket_Timeout=7");

        Assert.Equal("server", cfg.Host);
        Assert.Equal(4000, cfg.Port);
        Assert.Equal("db", cfg.Database);
        Assert.Equal("me", cfg.Username);
        Assert.Equal("secret", cfg.Password);
        Assert.Equal("prefer", cfg.SslMode);
        Assert.True(cfg.AllowInsecureDisable);
        Assert.Equal(5000, cfg.ConnectTimeoutMs);
        Assert.Equal(7000, cfg.SocketTimeoutMs);
    }

    [Fact]
    public void ParseManagerProxyParams()
    {
        var cfg = ScratchBirdConfig.FromConnectionString("scratchbird://admin:secret@localhost:3090/mydb?front_door_mode=manager_proxy&manager_auth_token=token&manager_client_flags=7");

        Assert.Equal("manager_proxy", cfg.FrontDoorMode);
        Assert.Equal("token", cfg.ManagerAuthToken);
        Assert.Equal((ushort)7, cfg.ManagerClientFlags);
    }

    [Fact]
    public void ParsePoolingOptions()
    {
        var cfg = ScratchBirdConfig.FromConnectionString("Host=localhost;Port=3092;Database=pooling;Username=app;Password=secret;Pooling=true;MinPoolSize=2;MaxPoolSize=25;ConnectionLifetime=60");

        Assert.True(cfg.Pooling);
        Assert.Equal(2, cfg.MinPoolSize);
        Assert.Equal(25, cfg.MaxPoolSize);
        Assert.Equal(60, cfg.ConnectionLifetime);
    }

    [Fact]
    public void ParseMetadataExpandSchemaParentsAliases()
    {
        var aliases = new[]
        {
            "metadataExpandSchemaParents",
            "metadata_expand_schema_parents",
            "expandSchemaParents",
            "expand_schema_parents",
            "dbeaverExpandSchemaParents",
            "dbeaver_expand_schema_parents"
        };

        foreach (var alias in aliases)
        {
            var uriCfg = ScratchBirdConfig.FromConnectionString($"scratchbird://user:pass@localhost:3092/mydb?{alias}=true");
            Assert.True(uriCfg.MetadataExpandSchemaParents);

            var kvCfg = ScratchBirdConfig.FromConnectionString($"Host=localhost;Port=3092;Database=mydb;{alias}=1");
            Assert.True(kvCfg.MetadataExpandSchemaParents);
        }
    }
}
