using System.Globalization;
using System.Text;
using System.Text.Json;

namespace ScratchBird.Data;

internal static class SqlHelpers
{
    public static string Substitute(string sql, IReadOnlyList<ScratchBirdParameter> parameters)
    {
        if (parameters.Count == 0)
        {
            return sql;
        }

        if (HasNamedParameters(sql))
        {
            return SubstituteNamed(sql, parameters);
        }

        return SubstitutePositional(sql, parameters);
    }

    private static bool HasNamedParameters(string sql)
    {
        return sql.Contains('@') || sql.Contains(':');
    }

    private static string SubstituteNamed(string sql, IReadOnlyList<ScratchBirdParameter> parameters)
    {
        var lookup = new Dictionary<string, ScratchBirdParameter>(StringComparer.OrdinalIgnoreCase);
        foreach (var param in parameters)
        {
            if (!string.IsNullOrEmpty(param.ParameterName))
            {
                lookup[param.ParameterName.TrimStart('@', ':')] = param;
            }
        }

        var sb = new StringBuilder();
        var i = 0;
        while (i < sql.Length)
        {
            var ch = sql[i];
            if (ch == '\'' && i + 1 < sql.Length)
            {
                sb.Append(ch);
                i++;
                while (i < sql.Length)
                {
                    sb.Append(sql[i]);
                    if (sql[i] == '\'' && (i + 1 >= sql.Length || sql[i + 1] != '\''))
                    {
                        i++;
                        break;
                    }
                    if (sql[i] == '\'' && i + 1 < sql.Length && sql[i + 1] == '\'')
                    {
                        i++;
                    }
                    i++;
                }
                continue;
            }

            if ((ch == '@' || ch == ':') && i + 1 < sql.Length && char.IsLetter(sql[i + 1]))
            {
                var j = i + 1;
                while (j < sql.Length && (char.IsLetterOrDigit(sql[j]) || sql[j] == '_'))
                {
                    j++;
                }
                var name = sql.Substring(i + 1, j - i - 1);
                if (lookup.TryGetValue(name, out var param))
                {
                    sb.Append(FormatParameter(param.Value));
                }
                else
                {
                    sb.Append(sql.Substring(i, j - i));
                }
                i = j;
                continue;
            }

            sb.Append(ch);
            i++;
        }

        return sb.ToString();
    }

    private static string SubstitutePositional(string sql, IReadOnlyList<ScratchBirdParameter> parameters)
    {
        var sb = new StringBuilder();
        var index = 0;
        var i = 0;
        while (i < sql.Length)
        {
            var ch = sql[i];
            if (ch == '?')
            {
                if (index < parameters.Count)
                {
                    sb.Append(FormatParameter(parameters[index].Value));
                    index++;
                }
                else
                {
                    sb.Append(ch);
                }
                i++;
                continue;
            }

            if (ch == '$' && i + 1 < sql.Length && char.IsDigit(sql[i + 1]))
            {
                var j = i + 1;
                var num = 0;
                while (j < sql.Length && char.IsDigit(sql[j]))
                {
                    num = num * 10 + (sql[j] - '0');
                    j++;
                }
                if (num > 0 && num <= parameters.Count)
                {
                    sb.Append(FormatParameter(parameters[num - 1].Value));
                }
                else
                {
                    sb.Append(sql.Substring(i, j - i));
                }
                i = j;
                continue;
            }

            if (ch == '\'' && i + 1 < sql.Length)
            {
                sb.Append(ch);
                i++;
                while (i < sql.Length)
                {
                    sb.Append(sql[i]);
                    if (sql[i] == '\'' && (i + 1 >= sql.Length || sql[i + 1] != '\''))
                    {
                        i++;
                        break;
                    }
                    if (sql[i] == '\'' && i + 1 < sql.Length && sql[i + 1] == '\'')
                    {
                        i++;
                    }
                    i++;
                }
                continue;
            }

            if (ch == '-' && i + 1 < sql.Length && sql[i + 1] == '-')
            {
                while (i < sql.Length && sql[i] != '\n')
                {
                    sb.Append(sql[i]);
                    i++;
                }
                continue;
            }

            if (ch == '/' && i + 1 < sql.Length && sql[i + 1] == '*')
            {
                sb.Append(ch).Append(sql[i + 1]);
                i += 2;
                while (i + 1 < sql.Length && !(sql[i] == '*' && sql[i + 1] == '/'))
                {
                    sb.Append(sql[i]);
                    i++;
                }
                if (i + 1 < sql.Length)
                {
                    sb.Append(sql[i]).Append(sql[i + 1]);
                    i += 2;
                }
                continue;
            }

            sb.Append(ch);
            i++;
        }

        return sb.ToString();
    }

    public static string FormatParameter(object? value)
    {
        if (value == null || value == DBNull.Value)
        {
            return "NULL";
        }

        switch (value)
        {
            case bool b:
                return b ? "TRUE" : "FALSE";
            case byte or sbyte or short or ushort or int or uint or long or ulong or float or double or decimal:
                return Convert.ToString(value, CultureInfo.InvariantCulture) ?? "NULL";
            case string s:
                return $"'{EscapeString(s)}'";
            case Guid guid:
                return $"UUID '{guid}'";
            case DateOnly dateOnly:
                return $"DATE '{dateOnly:yyyy-MM-dd}'";
            case TimeOnly timeOnly:
                return $"TIME '{timeOnly:HH:mm:ss.ffffff}'";
            case DateTime dateTime:
                return $"TIMESTAMP '{dateTime:yyyy-MM-dd HH:mm:ss.ffffff}'";
            case DateTimeOffset dto:
                return $"TIMESTAMPTZ '{dto:O}'";
            case byte[] bytes:
                return $"X'{Convert.ToHexString(bytes)}'";
            case IEnumerable<object?> list:
                return FormatArray(list);
        }

        if (value is System.Collections.IEnumerable enumerable && value is not string)
        {
            var items = new List<object?>();
            foreach (var item in enumerable)
            {
                items.Add(item);
            }
            return FormatArray(items);
        }

        if (value is JsonDocument jsonDoc)
        {
            return $"JSON '{EscapeString(jsonDoc.RootElement.GetRawText())}'";
        }

        if (value is not string)
        {
            try
            {
                var json = JsonSerializer.Serialize(value);
                return $"JSON '{EscapeString(json)}'";
            }
            catch
            {
                return $"'{EscapeString(value.ToString() ?? string.Empty)}'";
            }
        }

        return $"'{EscapeString(value.ToString() ?? string.Empty)}'";
    }

    private static string FormatArray(IEnumerable<object?> values)
    {
        var items = values.Select(v => v is IEnumerable<object?> nested && v is not string
            ? FormatArray(nested)
            : FormatParameter(v));
        return $"ARRAY[{string.Join(", ", items)}]";
    }

    private static string EscapeString(string value)
    {
        return value.Replace("\\", "\\\\").Replace("'", "''");
    }
}
