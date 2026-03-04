// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Linq;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class SqlHelpersTests
{
    [Fact]
    public void NormalizePositionalParameters()
    {
        var parameters = new ScratchBirdParameterCollection
        {
            new ScratchBirdParameter("p1", 42),
            new ScratchBirdParameter("p2", "hello")
        };
        var sql = "SELECT * FROM t WHERE id = ? AND name = ?";

        var normalized = SqlHelpers.Normalize(sql, parameters.Cast<ScratchBirdParameter>().ToList());

        Assert.Equal("SELECT * FROM t WHERE id = $1 AND name = $2", normalized.Sql);
        Assert.Equal(2, normalized.Parameters.Count);
        Assert.Equal(42, normalized.Parameters[0].Value);
        Assert.Equal("hello", normalized.Parameters[1].Value);
    }

    [Fact]
    public void NormalizeNamedParameters()
    {
        var parameters = new ScratchBirdParameterCollection
        {
            new ScratchBirdParameter("name", "Ada"),
            new ScratchBirdParameter("active", true)
        };
        var sql = "SELECT * FROM users WHERE name = @name AND active = :active";

        var normalized = SqlHelpers.Normalize(sql, parameters.Cast<ScratchBirdParameter>().ToList());

        Assert.Equal("SELECT * FROM users WHERE name = $1 AND active = $2", normalized.Sql);
        Assert.Equal(2, normalized.Parameters.Count);
        Assert.Equal("Ada", normalized.Parameters[0].Value);
        Assert.Equal(true, normalized.Parameters[1].Value);
    }

    [Fact]
    public void NormalizeCallableRewritesEscapeCallSyntax()
    {
        var parameters = new ScratchBirdParameterCollection
        {
            new ScratchBirdParameter("v", -3)
        };
        var normalized = SqlHelpers.NormalizeCallable(
            "{ ? = call abs(?) }",
            parameters.Cast<ScratchBirdParameter>().ToList());

        Assert.Equal("select abs($1) as return_value", normalized.Sql);
        Assert.Single(normalized.Parameters);
        Assert.Equal(-3, normalized.Parameters[0].Value);
    }

    [Fact]
    public void NormalizeCallableSqlPassesThroughNonEscapeSql()
    {
        var normalized = SqlHelpers.NormalizeCallableSql("SELECT 1");
        Assert.Equal("SELECT 1", normalized);
    }
}
