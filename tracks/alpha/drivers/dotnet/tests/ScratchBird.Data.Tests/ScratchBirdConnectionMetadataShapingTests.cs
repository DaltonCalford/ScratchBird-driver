// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Data;
using System.Linq;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class ScratchBirdConnectionMetadataShapingTests
{
    [Fact]
    public void ExpandSchemaParentsForMetadataAddsMissingParentsAndPreservesDistinctBranches()
    {
        var table = CreateSchemasTable(
            "users.alice.dev",
            "users.bob.dev",
            "analytics.prod",
            "sys");

        var expanded = ScratchBirdConnection.ExpandSchemaParentsForMetadata(table);

        Assert.Equal(
            new[]
            {
                "analytics",
                "analytics.prod",
                "sys",
                "users",
                "users.alice",
                "users.alice.dev",
                "users.bob",
                "users.bob.dev"
            },
            ReadSchemaNames(expanded));
    }

    [Fact]
    public void ShapeMetadataTableExpansionStillRespectsSchemaRestrictionPattern()
    {
        var table = CreateSchemasTable(
            "users.alice.dev",
            "users.bob.dev",
            "analytics.prod");

        var shaped = ScratchBirdConnection.ShapeMetadataTable(
            table,
            "schemas",
            new[] { null, "users.%" },
            expandSchemaParents: true);

        Assert.Equal(
            new[]
            {
                "users.alice",
                "users.alice.dev",
                "users.bob",
                "users.bob.dev"
            },
            ReadSchemaNames(shaped));
    }

    [Fact]
    public void ApplyRestrictionValuesForMetadataFiltersTablesBySchemaAndName()
    {
        var table = new DataTable("Tables");
        table.Columns.Add("table_schema", typeof(string));
        table.Columns.Add("table_name", typeof(string));
        table.Columns.Add("table_type", typeof(string));
        table.Rows.Add("users.alice", "orders", "BASE TABLE");
        table.Rows.Add("users.bob", "orders", "BASE TABLE");
        table.Rows.Add("sys", "users", "SYSTEM TABLE");

        var filtered = ScratchBirdConnection.ApplyRestrictionValuesForMetadata(
            table,
            "tables",
            new[] { null, "users.%", "orders", "BASE TABLE" });

        Assert.Equal(2, filtered.Rows.Count);
        Assert.All(
            filtered.Rows.Cast<DataRow>(),
            row => Assert.Equal("orders", row["table_name"]?.ToString()));
    }

    [Fact]
    public void ApplyRestrictionValuesForMetadataFiltersColumnsByColumnPattern()
    {
        var table = new DataTable("Columns");
        table.Columns.Add("table_schema", typeof(string));
        table.Columns.Add("table_name", typeof(string));
        table.Columns.Add("column_name", typeof(string));
        table.Rows.Add("users.alice", "orders", "id");
        table.Rows.Add("users.alice", "orders", "note");
        table.Rows.Add("users.alice", "orders", "net_total");

        var filtered = ScratchBirdConnection.ApplyRestrictionValuesForMetadata(
            table,
            "columns",
            new[] { null, "users.alice", "orders", "n_t%" });

        Assert.Equal(2, filtered.Rows.Count);
        var names = filtered.Rows.Cast<DataRow>()
            .Select(row => row["column_name"]?.ToString())
            .ToArray();
        Assert.Contains("note", names);
        Assert.Contains("net_total", names);
    }

    private static DataTable CreateSchemasTable(params string[] schemas)
    {
        var table = new DataTable("Schemas");
        table.Columns.Add("schema_id", typeof(int));
        table.Columns.Add("schema_name", typeof(string));
        table.Columns.Add("owner_id", typeof(int));
        table.Columns.Add("default_tablespace_id", typeof(int));

        for (var i = 0; i < schemas.Length; i++)
        {
            table.Rows.Add(i + 1, schemas[i], 1, 1);
        }

        return table;
    }

    private static string[] ReadSchemaNames(DataTable table)
    {
        return table.Rows.Cast<DataRow>()
            .Select(row => row["schema_name"]?.ToString())
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Cast<string>()
            .ToArray();
    }
}
