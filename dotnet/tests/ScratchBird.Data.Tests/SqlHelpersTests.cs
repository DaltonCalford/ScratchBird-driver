using System.Linq;
using ScratchBird.Data;
using Xunit;

namespace ScratchBird.Data.Tests;

public class SqlHelpersTests
{
    [Fact]
    public void SubstitutePositionalParameters()
    {
        var parameters = new ScratchBirdParameterCollection
        {
            new ScratchBirdParameter("p1", 42),
            new ScratchBirdParameter("p2", "hello")
        };
        var sql = "SELECT * FROM t WHERE id = ? AND name = ?";

        var rewritten = SqlHelpers.Substitute(sql, parameters.Cast<ScratchBirdParameter>().ToList());

        Assert.Equal("SELECT * FROM t WHERE id = 42 AND name = 'hello'", rewritten);
    }

    [Fact]
    public void SubstituteNamedParameters()
    {
        var parameters = new ScratchBirdParameterCollection
        {
            new ScratchBirdParameter("name", "Ada"),
            new ScratchBirdParameter("active", true)
        };
        var sql = "SELECT * FROM users WHERE name = @name AND active = :active";

        var rewritten = SqlHelpers.Substitute(sql, parameters.Cast<ScratchBirdParameter>().ToList());

        Assert.Equal("SELECT * FROM users WHERE name = 'Ada' AND active = TRUE", rewritten);
    }
}
