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
}
