// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Linq;
using System.Text;

namespace ScratchBird.Data;

internal sealed record NormalizedQuery(string Sql, List<ScratchBirdParameter> Parameters);

internal static class SqlHelpers
{
    public static NormalizedQuery Normalize(string sql, IReadOnlyList<ScratchBirdParameter> parameters)
    {
        if (parameters.Count == 0)
        {
            return new NormalizedQuery(sql, new List<ScratchBirdParameter>());
        }

        if (HasNamedParameters(sql))
        {
            return RewriteNamed(sql, parameters);
        }

        if (sql.Contains('?'))
        {
            return RewritePositional(sql, parameters);
        }

        return new NormalizedQuery(sql, parameters.ToList());
    }

    private static bool HasNamedParameters(string sql)
    {
        var inString = false;
        for (var i = 0; i + 1 < sql.Length; i++)
        {
            var ch = sql[i];
            if (ch == '\'')
            {
                inString = !inString;
                continue;
            }
            if (inString)
            {
                continue;
            }
            if ((ch == ':' || ch == '@') && IsIdentStart(sql[i + 1]))
            {
                return true;
            }
        }
        return false;
    }

    private static NormalizedQuery RewriteNamed(string sql, IReadOnlyList<ScratchBirdParameter> parameters)
    {
        var lookup = new Dictionary<string, ScratchBirdParameter>(StringComparer.OrdinalIgnoreCase);
        foreach (var param in parameters)
        {
            if (!string.IsNullOrEmpty(param.ParameterName))
            {
                lookup[param.ParameterName.TrimStart('@', ':')] = param;
            }
        }

        var ordered = new List<ScratchBirdParameter>();
        var sb = new StringBuilder();
        var inString = false;

        for (var i = 0; i < sql.Length;)
        {
            var ch = sql[i];
            if (ch == '\'')
            {
                inString = !inString;
                sb.Append(ch);
                i++;
                continue;
            }
            if (!inString && (ch == ':' || ch == '@') && i + 1 < sql.Length && IsIdentStart(sql[i + 1]))
            {
                var j = i + 1;
                while (j < sql.Length && IsIdentPart(sql[j]))
                {
                    j++;
                }
                var key = sql.Substring(i + 1, j - i - 1);
                if (!lookup.TryGetValue(key, out var param))
                {
                    throw new InvalidOperationException($"missing named parameter: {key}");
                }
                ordered.Add(param);
                sb.Append('$').Append(ordered.Count);
                i = j;
                continue;
            }
            sb.Append(ch);
            i++;
        }

        return new NormalizedQuery(sb.ToString(), ordered);
    }

    private static NormalizedQuery RewritePositional(string sql, IReadOnlyList<ScratchBirdParameter> parameters)
    {
        var ordered = new List<ScratchBirdParameter>();
        var sb = new StringBuilder();
        var inString = false;
        var index = 0;

        for (var i = 0; i < sql.Length;)
        {
            var ch = sql[i];
            if (ch == '\'')
            {
                inString = !inString;
                sb.Append(ch);
                i++;
                continue;
            }
            if (!inString && ch == '?')
            {
                if (index >= parameters.Count)
                {
                    throw new InvalidOperationException("not enough parameters");
                }
                ordered.Add(parameters[index]);
                index++;
                sb.Append('$').Append(ordered.Count);
                i++;
                continue;
            }
            sb.Append(ch);
            i++;
        }

        if (index < parameters.Count)
        {
            throw new InvalidOperationException("too many parameters");
        }

        return new NormalizedQuery(sb.ToString(), ordered);
    }

    private static bool IsIdentStart(char ch)
    {
        return char.IsLetter(ch) || ch == '_';
    }

    private static bool IsIdentPart(char ch)
    {
        return char.IsLetterOrDigit(ch) || ch == '_';
    }
}
