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

public class ErrorStateMappingTests
{
    [Fact]
    public void ExactSqlStateMapsToSpecificErrorType()
    {
        var ex = ScratchBirdSqlStateMapper.Create("exact", "42P01", null, null);
        Assert.IsType<ScratchBirdSyntaxException>(ex);
        Assert.Equal("42P01", ex.SqlState);
    }

    [Fact]
    public void SqlStateClassPrefixMapsToCategory()
    {
        var ex = ScratchBirdSqlStateMapper.Create("class", "22000", null, null);
        Assert.IsType<ScratchBirdDataException>(ex);
        Assert.Equal("22000", ex.SqlState);
    }

    [Fact]
    public void UnrecognizedStateFallsBackToBaseException()
    {
        var ex = ScratchBirdSqlStateMapper.Create("base", "ZZ123", null, null);
        Assert.IsType<ScratchBirdException>(ex);
        Assert.Equal("ZZ123", ex.SqlState);
    }

    [Fact]
    public void EmptySqlStateFallsBackToBaseException()
    {
        var ex = ScratchBirdSqlStateMapper.Create("empty", string.Empty, null, null);
        Assert.IsType<ScratchBirdException>(ex);
    }

    [Fact]
    public void SqlStateClassUsesExpectedConnectionCategory()
    {
        var ex = ScratchBirdSqlStateMapper.Create("class", "08012", null, null);
        Assert.IsType<ScratchBirdConnectionException>(ex);
        Assert.Equal("08012", ex.SqlState);
    }
}
