using System.Buffers.Binary;
using System.Globalization;
using System.Numerics;
using System.Text;

namespace ScratchBird.Data;

internal static class TypeDecoder
{
    public static object? Decode(WireType wireType, byte[]? data)
    {
        if (data == null)
        {
            return null;
        }

        switch (wireType)
        {
            case WireType.Boolean:
                return data.Length > 0 && data[0] == 1;
            case WireType.Int16:
                return ReadInt16(data);
            case WireType.Int32:
                return ReadInt32(data);
            case WireType.Int64:
                return ReadInt64(data);
            case WireType.Float32:
                return ReadFloat(data);
            case WireType.Float64:
                return ReadDouble(data);
            case WireType.Decimal:
                return ParseDecimal(data);
            case WireType.Varchar:
            case WireType.Char:
            case WireType.Json:
            case WireType.Jsonb:
            case WireType.Xml:
            case WireType.Tsvector:
            case WireType.Tsquery:
                return Encoding.UTF8.GetString(data);
            case WireType.Bytea:
                return data;
            case WireType.Date:
                return DateOnly.FromDateTime(new DateTime(2000, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddDays(ReadInt32(data)));
            case WireType.Time:
            {
                var micros = ReadInt64(data);
                var ticks = micros * 10;
                return TimeOnly.FromTimeSpan(TimeSpan.FromTicks(ticks));
            }
            case WireType.Timestamp:
            {
                var micros = ReadInt64(data);
                return FromUnixMicros(micros).DateTime;
            }
            case WireType.Timestamptz:
            {
                var micros = ReadInt64(data);
                if (data.Length >= 10)
                {
                    var offsetMinutes = ReadInt16(data.AsSpan(8, 2));
                    var offset = TimeSpan.FromMinutes(offsetMinutes);
                    return new DateTimeOffset(FromUnixMicros(micros).UtcDateTime, offset);
                }
                return FromUnixMicros(micros);
            }
            case WireType.Interval:
            {
                var months = ReadInt32(data);
                var days = ReadInt32(data.AsSpan(4, 4));
                var micros = ReadInt64(data.AsSpan(8));
                return new { months, days, micros };
            }
            case WireType.Uuid:
                return Guid.Parse(BytesToUuid(data));
            case WireType.Money:
            {
                var cents = ReadInt64(data);
                return cents / 100m;
            }
            case WireType.Inet:
            case WireType.Cidr:
                return Encoding.UTF8.GetString(data);
            case WireType.Array:
                return ParseArrayLiteral(Encoding.UTF8.GetString(data));
            case WireType.Vector:
                return ParseVectorLiteral(Encoding.UTF8.GetString(data));
            default:
                return data;
        }
    }

    public static Type GetClrType(WireType wireType)
    {
        return wireType switch
        {
            WireType.Boolean => typeof(bool),
            WireType.Int16 => typeof(short),
            WireType.Int32 => typeof(int),
            WireType.Int64 => typeof(long),
            WireType.Float32 => typeof(float),
            WireType.Float64 => typeof(double),
            WireType.Decimal => typeof(decimal),
            WireType.Varchar => typeof(string),
            WireType.Char => typeof(string),
            WireType.Json => typeof(string),
            WireType.Jsonb => typeof(string),
            WireType.Xml => typeof(string),
            WireType.Tsvector => typeof(string),
            WireType.Tsquery => typeof(string),
            WireType.Bytea => typeof(byte[]),
            WireType.Date => typeof(DateOnly),
            WireType.Time => typeof(TimeOnly),
            WireType.Timestamp => typeof(DateTime),
            WireType.Timestamptz => typeof(DateTimeOffset),
            WireType.Interval => typeof(object),
            WireType.Uuid => typeof(Guid),
            WireType.Money => typeof(decimal),
            WireType.Inet => typeof(string),
            WireType.Cidr => typeof(string),
            WireType.Array => typeof(object[]),
            WireType.Vector => typeof(float[]),
            _ => typeof(object)
        };
    }

    private static short ReadInt16(ReadOnlySpan<byte> data)
    {
        return BitConverter.IsLittleEndian ? BinaryPrimitives.ReadInt16LittleEndian(data) : BinaryPrimitives.ReadInt16BigEndian(data);
    }

    private static int ReadInt32(ReadOnlySpan<byte> data)
    {
        return BitConverter.IsLittleEndian ? BinaryPrimitives.ReadInt32LittleEndian(data) : BinaryPrimitives.ReadInt32BigEndian(data);
    }

    private static long ReadInt64(ReadOnlySpan<byte> data)
    {
        return BitConverter.IsLittleEndian ? BinaryPrimitives.ReadInt64LittleEndian(data) : BinaryPrimitives.ReadInt64BigEndian(data);
    }

    private static float ReadFloat(ReadOnlySpan<byte> data)
    {
        if (!BitConverter.IsLittleEndian)
        {
            var tmp = data.ToArray();
            Array.Reverse(tmp);
            return BitConverter.ToSingle(tmp, 0);
        }
        return BitConverter.ToSingle(data);
    }

    private static double ReadDouble(ReadOnlySpan<byte> data)
    {
        if (!BitConverter.IsLittleEndian)
        {
            var tmp = data.ToArray();
            Array.Reverse(tmp);
            return BitConverter.ToDouble(tmp, 0);
        }
        return BitConverter.ToDouble(data);
    }

    private static string BytesToUuid(byte[] data)
    {
        var hex = Convert.ToHexString(data).ToLowerInvariant();
        return $"{hex[..8]}-{hex.Substring(8, 4)}-{hex.Substring(12, 4)}-{hex.Substring(16, 4)}-{hex.Substring(20)}";
    }

    private static object ParseDecimal(byte[] data)
    {
        var text = Encoding.UTF8.GetString(data);
        if (decimal.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var value))
        {
            return value;
        }
        return text;
    }

    private static DateTimeOffset FromUnixMicros(long micros)
    {
        var seconds = micros / 1_000_000;
        var remainder = micros % 1_000_000;
        var dto = DateTimeOffset.FromUnixTimeSeconds(seconds);
        return dto.AddTicks(remainder * 10);
    }

    private static object[] ParseArrayLiteral(string text)
    {
        var trimmed = text.Trim();
        if (string.IsNullOrEmpty(trimmed) || trimmed == "{}")
        {
            return Array.Empty<object>();
        }
        if (trimmed.StartsWith("{") && trimmed.EndsWith("}"))
        {
            trimmed = trimmed.Substring(1, trimmed.Length - 2);
        }
        return SplitArrayItems(trimmed).ToArray();
    }

    private static List<object?> SplitArrayItems(string text)
    {
        var items = new List<object?>();
        var depth = 0;
        var sb = new StringBuilder();
        foreach (var ch in text)
        {
            if (ch == '{')
            {
                depth++;
                sb.Append(ch);
            }
            else if (ch == '}')
            {
                depth = Math.Max(0, depth - 1);
                sb.Append(ch);
            }
            else if (ch == ',' && depth == 0)
            {
                items.Add(ParseArrayItem(sb.ToString()));
                sb.Clear();
            }
            else
            {
                sb.Append(ch);
            }
        }
        if (sb.Length > 0 || text.Length > 0)
        {
            items.Add(ParseArrayItem(sb.ToString()));
        }
        return items;
    }

    private static object? ParseArrayItem(string raw)
    {
        var token = raw.Trim();
        if (string.Equals(token, "NULL", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }
        if (token.StartsWith("{") && token.EndsWith("}"))
        {
            return ParseArrayLiteral(token);
        }
        if (token.StartsWith("[") && token.EndsWith("]"))
        {
            return ParseVectorLiteral(token);
        }
        if (bool.TryParse(token, out var b))
        {
            return b;
        }
        if (int.TryParse(token, NumberStyles.Integer, CultureInfo.InvariantCulture, out var i))
        {
            return i;
        }
        if (double.TryParse(token, NumberStyles.Float, CultureInfo.InvariantCulture, out var d))
        {
            return d;
        }
        return token;
    }

    private static float[] ParseVectorLiteral(string text)
    {
        var trimmed = text.Trim();
        if (trimmed.StartsWith("[") && trimmed.EndsWith("]"))
        {
            trimmed = trimmed.Substring(1, trimmed.Length - 2);
        }
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return Array.Empty<float>();
        }
        return trimmed.Split(',')
            .Select(s => float.TryParse(s.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var f) ? f : 0f)
            .ToArray();
    }
}
