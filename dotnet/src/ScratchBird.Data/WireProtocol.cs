using System.Buffers.Binary;
using System.Text;

namespace ScratchBird.Data;

internal enum MessageType : byte
{
    ConnectRequest = 0x01,
    ConnectResponse = 0x02,
    Disconnect = 0x03,
    AuthRequest = 0x10,
    AuthResponse = 0x11,
    Query = 0x20,
    QueryResult = 0x21,
    QueryError = 0x22,
    QueryCancel = 0x23,
    Prepare = 0x30,
    PrepareResponse = 0x31,
    Execute = 0x32,
    CloseStatement = 0x33,
    Describe = 0x34,
    DescribeResponse = 0x35,
    BeginTransaction = 0x40,
    Commit = 0x41,
    Rollback = 0x42,
    Savepoint = 0x43,
    ReleaseSavepoint = 0x44,
    RollbackTo = 0x45,
    TransactionStatus = 0x46,
    RowDescription = 0x50,
    RowData = 0x51,
    EndOfResults = 0x52,
    CommandComplete = 0x53,
    CopyData = 0x70,
    CopyDone = 0x71,
    CopyFail = 0x72,
    CopyInResponse = 0x73,
    CopyOutResponse = 0x74,
    CopyBothResponse = 0x75,
    StreamControl = 0x76,
    StreamReady = 0x77,
    StreamData = 0x78,
    StreamEnd = 0x79
}

internal enum AuthMethod : byte
{
    Password = 0,
    Md5 = 1,
    ScramSha256 = 2,
    ScramSha512 = 3
}

internal enum AuthStatus : byte
{
    Ok = 0,
    Error = 1,
    Continue = 2
}

internal enum WireType : byte
{
    NullType = 0x00,
    Boolean = 0x01,
    Int16 = 0x02,
    Int32 = 0x03,
    Int64 = 0x04,
    Float32 = 0x05,
    Float64 = 0x06,
    Decimal = 0x07,
    Varchar = 0x08,
    Char = 0x09,
    Bytea = 0x0A,
    Date = 0x0B,
    Time = 0x0C,
    Timestamp = 0x0D,
    Timestamptz = 0x0E,
    Interval = 0x0F,
    Uuid = 0x10,
    Json = 0x11,
    Jsonb = 0x12,
    Array = 0x13,
    Composite = 0x14,
    Geometry = 0x15,
    Vector = 0x16,
    Money = 0x17,
    Xml = 0x18,
    Inet = 0x19,
    Cidr = 0x1A,
    Macaddr = 0x1B,
    Tsvector = 0x1C,
    Tsquery = 0x1D,
    Range = 0x1E,
    Unknown = 0xFF
}

internal sealed class ProtocolMessage
{
    public MessageType Type { get; }
    public byte Flags { get; }
    public byte[] Payload { get; }

    public ProtocolMessage(MessageType type, byte[] payload, byte flags = 0)
    {
        Type = type;
        Payload = payload;
        Flags = flags;
    }

    public byte[] ToBytes()
    {
        var buffer = new byte[12 + Payload.Length];
        BinaryPrimitives.WriteUInt32LittleEndian(buffer.AsSpan(0, 4), ProtocolConstants.Magic);
        BinaryPrimitives.WriteUInt16LittleEndian(buffer.AsSpan(4, 2), ProtocolConstants.Version);
        buffer[6] = (byte)Type;
        buffer[7] = Flags;
        BinaryPrimitives.WriteUInt32LittleEndian(buffer.AsSpan(8, 4), (uint)Payload.Length);
        Buffer.BlockCopy(Payload, 0, buffer, 12, Payload.Length);
        return buffer;
    }

    public static (MessageType Type, byte Flags, int Length) ParseHeader(ReadOnlySpan<byte> header)
    {
        if (header.Length != 12)
        {
            throw new InvalidOperationException("Invalid header length");
        }
        var magic = BinaryPrimitives.ReadUInt32LittleEndian(header.Slice(0, 4));
        if (magic != ProtocolConstants.Magic)
        {
            throw new InvalidOperationException("Invalid protocol magic");
        }
        var length = (int)BinaryPrimitives.ReadUInt32LittleEndian(header.Slice(8, 4));
        return ((MessageType)header[6], header[7], length);
    }
}

internal static class ProtocolConstants
{
    public const uint Magic = 0x42444253;
    public const ushort VersionMajor = 1;
    public const ushort VersionMinor = 0;
    public const ushort Version = (ushort)((VersionMajor << 8) | VersionMinor);
}

internal sealed class ColumnInfo
{
    public string Name { get; set; } = string.Empty;
    public WireType WireType { get; set; } = WireType.Unknown;
    public uint TypeModifier { get; set; }
    public ushort FormatCode { get; set; }
}

internal sealed class ColumnValue
{
    public byte[]? Data { get; set; }
}

internal static class ProtocolCodec
{
    public static ProtocolMessage BuildConnectRequest(string database, string clientName, int pid)
    {
        var payload = new byte[2 + 2 + 4 + 256 + 64 + 32];
        var span = payload.AsSpan();
        BinaryPrimitives.WriteUInt16LittleEndian(span.Slice(0, 2), ProtocolConstants.Version);
        BinaryPrimitives.WriteUInt16LittleEndian(span.Slice(2, 2), 0);
        BinaryPrimitives.WriteUInt32LittleEndian(span.Slice(4, 4), (uint)pid);
        WriteNullTerminated(span.Slice(8, 256), database);
        WriteNullTerminated(span.Slice(8 + 256, 64), clientName);
        WriteNullTerminated(span.Slice(8 + 256 + 64, 32), "1.0.0");
        return new ProtocolMessage(MessageType.ConnectRequest, payload);
    }

    public static (bool Success, byte[] SessionId, ushort Version, string ServerName, string ServerVersion, string Error) ParseConnectResponse(byte[] payload)
    {
        if (payload.Length < 1 + 2 + 2 + 16 + 64 + 32)
        {
            throw new InvalidOperationException("Connect response truncated");
        }
        var offset = 0;
        var status = payload[offset];
        offset += 1;
        var version = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        offset += 2;
        var sessionId = payload.AsSpan(offset, 16).ToArray();
        offset += 16;
        var serverName = ReadNullTerminated(payload.AsSpan(offset, 64));
        offset += 64;
        var serverVersion = ReadNullTerminated(payload.AsSpan(offset, 32));
        offset += 32;
        var error = string.Empty;
        if (status != 0 && offset + 2 <= payload.Length)
        {
            var len = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
            offset += 2;
            error = Encoding.UTF8.GetString(payload, offset, Math.Min(len, payload.Length - offset));
        }
        return (status == 0, sessionId, version, serverName, serverVersion, error);
    }

    public static ProtocolMessage BuildAuthRequest(byte[] sessionId, string username, AuthMethod method, byte[] payload)
    {
        if (sessionId.Length != 16)
        {
            throw new InvalidOperationException("sessionId must be 16 bytes");
        }
        var buffer = new byte[16 + 64 + 1 + 2 + payload.Length];
        Buffer.BlockCopy(sessionId, 0, buffer, 0, 16);
        WriteNullTerminated(buffer.AsSpan(16, 64), username);
        buffer[16 + 64] = (byte)method;
        BinaryPrimitives.WriteUInt16LittleEndian(buffer.AsSpan(16 + 64 + 1, 2), (ushort)payload.Length);
        Buffer.BlockCopy(payload, 0, buffer, 16 + 64 + 1 + 2, payload.Length);
        return new ProtocolMessage(MessageType.AuthRequest, buffer);
    }

    public static (AuthStatus Status, uint UserId, string Error, byte[] Extra) ParseAuthResponse(byte[] payload)
    {
        if (payload.Length < 1 + 4 + 256)
        {
            throw new InvalidOperationException("Auth response truncated");
        }
        var status = (AuthStatus)payload[0];
        var userId = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(1, 4));
        var error = ReadNullTerminated(payload.AsSpan(5, 256));
        var extra = payload[(5 + 256)..];
        return (status, userId, error, extra);
    }

    public static ProtocolMessage BuildQuery(byte[] sessionId, string sql, byte flags = 0)
    {
        if (sessionId.Length != 16)
        {
            throw new InvalidOperationException("sessionId must be 16 bytes");
        }
        var sqlBytes = Encoding.UTF8.GetBytes(sql);
        var payload = new byte[16 + 4 + 1 + sqlBytes.Length];
        Buffer.BlockCopy(sessionId, 0, payload, 0, 16);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(16, 4), (uint)sqlBytes.Length);
        payload[20] = flags;
        Buffer.BlockCopy(sqlBytes, 0, payload, 21, sqlBytes.Length);
        return new ProtocolMessage(MessageType.Query, payload);
    }

    public static List<ColumnInfo> ParseRowDescription(byte[] payload)
    {
        if (payload.Length < 2)
        {
            throw new InvalidOperationException("Row description truncated");
        }
        var offset = 0;
        var count = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var columns = new List<ColumnInfo>(count);
        for (var i = 0; i < count; i++)
        {
            var nameLen = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
            offset += 2;
            var name = Encoding.UTF8.GetString(payload, offset, nameLen);
            offset += nameLen;
            var wireType = (WireType)payload[offset];
            offset += 1;
            var modifier = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
            offset += 4;
            var format = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
            offset += 2;
            columns.Add(new ColumnInfo
            {
                Name = name,
                WireType = wireType,
                TypeModifier = modifier,
                FormatCode = format
            });
        }
        return columns;
    }

    public static List<ColumnValue> ParseRowData(byte[] payload)
    {
        if (payload.Length < 2)
        {
            throw new InvalidOperationException("Row data truncated");
        }
        var offset = 0;
        var count = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var values = new List<ColumnValue>(count);
        for (var i = 0; i < count; i++)
        {
            var length = BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(offset, 4));
            offset += 4;
            if (length < 0)
            {
                values.Add(new ColumnValue { Data = null });
                continue;
            }
            var data = payload.AsSpan(offset, length).ToArray();
            offset += length;
            values.Add(new ColumnValue { Data = data });
        }
        return values;
    }

    public static (string Tag, long RowsAffected) ParseCommandComplete(byte[] payload)
    {
        if (payload.Length < 64 + 8)
        {
            throw new InvalidOperationException("Command complete truncated");
        }
        var tag = ReadNullTerminated(payload.AsSpan(0, 64));
        var rows = BinaryPrimitives.ReadInt64LittleEndian(payload.AsSpan(64, 8));
        return (tag, rows);
    }

    public static (byte Status, uint ColumnCount, long RowCount) ParseQueryResult(byte[] payload)
    {
        if (payload.Length < 1 + 4 + 8)
        {
            throw new InvalidOperationException("Query result truncated");
        }
        var status = payload[0];
        var count = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(1, 4));
        var rows = BinaryPrimitives.ReadInt64LittleEndian(payload.AsSpan(5, 8));
        return (status, count, rows);
    }

    public static (uint ErrorCode, string SqlState, string Message, string Detail, string Hint) ParseQueryError(byte[] payload)
    {
        if (payload.Length < 4 + 6 + 2 + 2 + 2)
        {
            throw new InvalidOperationException("Query error truncated");
        }
        var offset = 0;
        var errorCode = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
        offset += 4;
        var sqlState = ReadNullTerminated(payload.AsSpan(offset, 6));
        offset += 6;
        var messageLen = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var detailLen = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var hintLen = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var message = Encoding.UTF8.GetString(payload, offset, messageLen);
        offset += messageLen;
        var detail = Encoding.UTF8.GetString(payload, offset, detailLen);
        offset += detailLen;
        var hint = Encoding.UTF8.GetString(payload, offset, hintLen);
        return (errorCode, sqlState, message, detail, hint);
    }

    public static ProtocolMessage BuildCommit(byte[] sessionId) => new ProtocolMessage(MessageType.Commit, sessionId);

    public static ProtocolMessage BuildRollback(byte[] sessionId) => new ProtocolMessage(MessageType.Rollback, sessionId);

    public static ProtocolMessage BuildBegin(byte[] sessionId, byte isolationLevel = 0, bool readOnly = false)
    {
        var payload = new byte[16 + 1 + 1];
        Buffer.BlockCopy(sessionId, 0, payload, 0, 16);
        payload[16] = isolationLevel;
        payload[17] = readOnly ? (byte)1 : (byte)0;
        return new ProtocolMessage(MessageType.BeginTransaction, payload);
    }

    public static ProtocolMessage BuildDisconnect(byte[] sessionId) => new ProtocolMessage(MessageType.Disconnect, sessionId);

    private static void WriteNullTerminated(Span<byte> buffer, string value)
    {
        var encoded = Encoding.UTF8.GetBytes(value ?? string.Empty);
        var len = Math.Min(encoded.Length, buffer.Length - 1);
        encoded.AsSpan(0, len).CopyTo(buffer);
        buffer.Slice(len).Clear();
    }

    private static string ReadNullTerminated(ReadOnlySpan<byte> buffer)
    {
        var idx = buffer.IndexOf((byte)0);
        if (idx < 0) idx = buffer.Length;
        return Encoding.UTF8.GetString(buffer.Slice(0, idx));
    }
}
