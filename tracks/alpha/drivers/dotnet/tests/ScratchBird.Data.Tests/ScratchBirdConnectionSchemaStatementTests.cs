// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Reflection;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class ScratchBirdConnectionSchemaStatementTests
{
    [Fact]
    public void BuildSchemaStatementSupportsRecursiveSchemaPath()
    {
        Assert.Equal("SET SCHEMA \"public\".\"examples\"",
            BuildSchemaStatement("public.examples"));
    }

    [Fact]
    public void BuildSchemaStatementSupportsRecursiveSearchPathList()
    {
        Assert.Equal("SET SEARCH_PATH TO \"public\".\"examples\", \"compat\".\"mysql\"",
            BuildSchemaStatement("public.examples, compat.mysql"));
    }

    [Fact]
    public void BuildSchemaStatementPreservesQuotedSegments()
    {
        Assert.Equal("SET SCHEMA \"Public\".\"Examples\"",
            BuildSchemaStatement("\"Public\".\"Examples\""));
    }

    private static string BuildSchemaStatement(string input)
    {
        var method = typeof(ScratchBirdConnection).GetMethod(
            "BuildSchemaStatement",
            BindingFlags.NonPublic | BindingFlags.Static);
        Assert.NotNull(method);
        return (string)method!.Invoke(null, new object[] { input })!;
    }
}
