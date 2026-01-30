// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Buffers.Binary;
using System.Linq;
using System.Text;

namespace ScratchBird.Data;

internal enum MessageType : byte
{
    STARTUP = 0x01,
    AUTH_RESPONSE = 0x02,
    QUERY = 0x03,
    PARSE = 0x04,
    BIND = 0x05,
    DESCRIBE = 0x06,
    EXECUTE = 0x07,
    CLOSE = 0x08,
    SYNC = 0x09,
    FLUSH = 0x0A,
    CANCEL = 0x0B,
    COPY_DATA = 0x0D,
    COPY_DONE = 0x0E,
    COPY_FAIL = 0x0F,

    AUTH_REQUEST = 0x40,
    AUTH_OK = 0x41,
    AUTH_CONTINUE = 0x42,
    READY = 0x43,
    ROW_DESCRIPTION = 0x44,
    DATA_ROW = 0x45,
    COMMAND_COMPLETE = 0x46,
    EMPTY_QUERY = 0x47,
    ERROR = 0x48,
    NOTICE = 0x49,
    PARSE_COMPLETE = 0x4A,
    BIND_COMPLETE = 0x4B,
    CLOSE_COMPLETE = 0x4C,
    PORTAL_SUSPENDED = 0x4D,
    NO_DATA = 0x4E,
    PARAMETER_STATUS = 0x4F,
    PARAMETER_DESCRIPTION = 0x50,
    COPY_IN_RESPONSE = 0x51,
    COPY_OUT_RESPONSE = 0x52,
    COPY_BOTH_RESPONSE = 0x53,
    NOTIFICATION = 0x54,
    NEGOTIATE_VERSION = 0x56,
    STREAM_READY = 0x59,
    STREAM_DATA = 0x5A,
    STREAM_END = 0x5B,
    TXN_STATUS = 0x5C,
    PONG = 0x5D
}

internal enum AuthMethod : byte
{
    OK = 0,
    PASSWORD = 1,
    MD5 = 2,
    SCRAM_SHA_256 = 3,
    CERTIFICATE = 4,
    GSSAPI = 5,
    SSPI = 6,
    LDAP = 7,
    SAML = 8,
    OIDC = 9,
    MFA_TOTP = 10,
    CLUSTER_PKI = 11
}

internal static class ProtocolConstants
{
    public const uint Magic = 0x53425750; // "SBWP"
    public const byte VersionMajor = 1;
    public const byte VersionMinor = 1;
    public const ushort Version = (ushort)((VersionMajor << 8) | VersionMinor);
    public const int HeaderSize = 40;
    public const int MaxMessageSize = 1024 * 1024 * 1024;

    public const byte MsgFlagCompressed = 0x01;
    public const byte MsgFlagContinued = 0x02;
    public const byte MsgFlagFinal = 0x04;
    public const byte MsgFlagUrgent = 0x08;
    public const byte MsgFlagEncrypted = 0x10;
    public const byte MsgFlagChecksum = 0x20;

    public const ulong FeatureCompression = 1UL << 0;
    public const ulong FeatureStreaming = 1UL << 1;
    public const ulong FeatureSblr = 1UL << 2;
    public const ulong FeatureFederation = 1UL << 3;
    public const ulong FeatureNotifications = 1UL << 4;
    public const ulong FeatureQueryPlan = 1UL << 5;
    public const ulong FeatureBatch = 1UL << 6;
    public const ulong FeaturePipeline = 1UL << 7;
    public const ulong FeatureBinaryCopy = 1UL << 8;
    public const ulong FeatureSavepoints = 1UL << 9;
    public const ulong Feature2Pc = 1UL << 10;
    public const ulong FeatureChecksums = 1UL << 11;
}

internal sealed class MessageHeader
{
    public byte Type { get; }
    public byte Flags { get; }
    public uint Length { get; }
    public uint Sequence { get; }
    public byte[] AttachmentId { get; }
    public ulong TxnId { get; }

    public MessageHeader(byte type, byte flags, uint length, uint sequence, byte[] attachmentId, ulong txnId)
    {
        Type = type;
        Flags = flags;
        Length = length;
        Sequence = sequence;
        AttachmentId = attachmentId.Length == 16 ? attachmentId : throw new ArgumentException("AttachmentId must be 16 bytes");
        TxnId = txnId;
    }
}

internal sealed class ProtocolMessage
{
    public MessageHeader Header { get; }
    public byte[] Payload { get; }

    public ProtocolMessage(MessageHeader header, byte[] payload)
    {
        Header = header;
        Payload = payload;
    }

    public byte[] ToBytes()
    {
        var buffer = new byte[ProtocolConstants.HeaderSize + Payload.Length];
        BinaryPrimitives.WriteUInt32LittleEndian(buffer.AsSpan(0, 4), ProtocolConstants.Magic);
        buffer[4] = ProtocolConstants.VersionMajor;
        buffer[5] = ProtocolConstants.VersionMinor;
        buffer[6] = Header.Type;
        buffer[7] = Header.Flags;
        BinaryPrimitives.WriteUInt32LittleEndian(buffer.AsSpan(8, 4), (uint)Payload.Length);
        BinaryPrimitives.WriteUInt32LittleEndian(buffer.AsSpan(12, 4), Header.Sequence);
        Buffer.BlockCopy(Header.AttachmentId, 0, buffer, 16, 16);
        BinaryPrimitives.WriteUInt64LittleEndian(buffer.AsSpan(32, 8), Header.TxnId);
        if (Payload.Length > 0)
        {
            Buffer.BlockCopy(Payload, 0, buffer, ProtocolConstants.HeaderSize, Payload.Length);
        }
        return buffer;
    }

    public static MessageHeader ParseHeader(ReadOnlySpan<byte> header)
    {
        if (header.Length != ProtocolConstants.HeaderSize)
        {
            throw new InvalidOperationException("Invalid header length");
        }
        var magic = BinaryPrimitives.ReadUInt32LittleEndian(header.Slice(0, 4));
        if (magic != ProtocolConstants.Magic)
        {
            throw new InvalidOperationException("Invalid protocol magic");
        }
        var major = header[4];
        var minor = header[5];
        if (major != ProtocolConstants.VersionMajor || minor != ProtocolConstants.VersionMinor)
        {
            throw new InvalidOperationException("Unsupported protocol version");
        }
        var type = header[6];
        var flags = header[7];
        var length = BinaryPrimitives.ReadUInt32LittleEndian(header.Slice(8, 4));
        if (length > ProtocolConstants.MaxMessageSize)
        {
            throw new InvalidOperationException("Payload too large");
        }
        var sequence = BinaryPrimitives.ReadUInt32LittleEndian(header.Slice(12, 4));
        var attachmentId = header.Slice(16, 16).ToArray();
        var txnId = BinaryPrimitives.ReadUInt64LittleEndian(header.Slice(32, 8));
        return new MessageHeader(type, flags, length, sequence, attachmentId, txnId);
    }
}

internal sealed class ColumnInfo
{
    public string Name { get; set; } = string.Empty;
    public uint TableOid { get; set; }
    public ushort ColumnIndex { get; set; }
    public uint TypeOid { get; set; }
    public short TypeSize { get; set; }
    public int TypeModifier { get; set; }
    public byte Format { get; set; }
    public bool Nullable { get; set; }
}

internal sealed class ColumnValue
{
    public byte[]? Data { get; set; }
}

internal sealed class ParamValue
{
    public ushort Format { get; set; }
    public byte[]? Data { get; set; }
    public bool IsNull { get; set; }
}

internal static class ProtocolCodec
{
    public static byte[] BuildStartupPayload(ulong features, IReadOnlyDictionary<string, string> parameters)
    {
        var paramBytes = BuildParamList(parameters);
        var payload = new byte[2 + 2 + 8 + paramBytes.Length];
        payload[0] = ProtocolConstants.VersionMajor;
        payload[1] = ProtocolConstants.VersionMinor;
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(2, 2), 0);
        BinaryPrimitives.WriteUInt64LittleEndian(payload.AsSpan(4, 8), features);
        Buffer.BlockCopy(paramBytes, 0, payload, 12, paramBytes.Length);
        return payload;
    }

    private static byte[] BuildParamList(IReadOnlyDictionary<string, string> parameters)
    {
        var parts = new List<byte[]>();
        foreach (var kvp in parameters)
        {
            parts.Add(Encoding.UTF8.GetBytes(kvp.Key));
            parts.Add(new byte[] { 0 });
            parts.Add(Encoding.UTF8.GetBytes(kvp.Value));
            parts.Add(new byte[] { 0 });
        }
        parts.Add(new byte[] { 0 });
        var length = parts.Sum(part => part.Length);
        var buffer = new byte[length];
        var offset = 0;
        foreach (var part in parts)
        {
            Buffer.BlockCopy(part, 0, buffer, offset, part.Length);
            offset += part.Length;
        }
        return buffer;
    }

    public static (AuthMethod Method, byte[] Data) ParseAuthRequest(byte[] payload)
    {
        if (payload.Length < 4)
        {
            throw new InvalidOperationException("Auth request truncated");
        }
        var method = (AuthMethod)payload[0];
        var data = payload.AsSpan(4).ToArray();
        return (method, data);
    }

    public static (AuthMethod Method, byte Stage, byte[] Data) ParseAuthContinue(byte[] payload)
    {
        if (payload.Length < 8)
        {
            throw new InvalidOperationException("Auth continue truncated");
        }
        var method = (AuthMethod)payload[0];
        var stage = payload[1];
        var dataLen = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(4, 4));
        if (8 + dataLen > payload.Length)
        {
            throw new InvalidOperationException("Auth continue truncated");
        }
        var data = payload.AsSpan(8, (int)dataLen).ToArray();
        return (method, stage, data);
    }

    public static (byte[] SessionId, byte[] ServerInfo) ParseAuthOk(byte[] payload)
    {
        if (payload.Length < 20)
        {
            throw new InvalidOperationException("Auth ok truncated");
        }
        var sessionId = payload.AsSpan(0, 16).ToArray();
        var infoLen = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(16, 4));
        if (20 + infoLen > payload.Length)
        {
            throw new InvalidOperationException("Auth ok truncated");
        }
        var serverInfo = payload.AsSpan(20, (int)infoLen).ToArray();
        return (sessionId, serverInfo);
    }

    public static byte[] BuildQueryPayload(string sql, uint flags, uint maxRows, uint timeoutMs)
    {
        var sqlBytes = Encoding.UTF8.GetBytes(sql + "\0");
        var payload = new byte[12 + sqlBytes.Length];
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(0, 4), flags);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(4, 4), maxRows);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(8, 4), timeoutMs);
        Buffer.BlockCopy(sqlBytes, 0, payload, 12, sqlBytes.Length);
        return payload;
    }

    public static byte[] BuildParsePayload(string statementName, string sql, IReadOnlyList<uint> paramTypes)
    {
        var nameBytes = Encoding.UTF8.GetBytes(statementName);
        var sqlBytes = Encoding.UTF8.GetBytes(sql);
        var payloadLen = 4 + nameBytes.Length + 4 + sqlBytes.Length + 2 + 2 + paramTypes.Count * 4;
        var payload = new byte[payloadLen];
        var offset = 0;
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(offset, 4), (uint)nameBytes.Length);
        offset += 4;
        Buffer.BlockCopy(nameBytes, 0, payload, offset, nameBytes.Length);
        offset += nameBytes.Length;
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(offset, 4), (uint)sqlBytes.Length);
        offset += 4;
        Buffer.BlockCopy(sqlBytes, 0, payload, offset, sqlBytes.Length);
        offset += sqlBytes.Length;
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), (ushort)paramTypes.Count);
        offset += 2;
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), 0);
        offset += 2;
        foreach (var oid in paramTypes)
        {
            BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(offset, 4), oid);
            offset += 4;
        }
        return payload;
    }

    public static byte[] BuildBindPayload(string portalName, string statementName, IReadOnlyList<ParamValue> parameters, IReadOnlyList<ushort> resultFormats)
    {
        var portalBytes = Encoding.UTF8.GetBytes(portalName);
        var stmtBytes = Encoding.UTF8.GetBytes(statementName);
        var paramFormats = parameters.Select(param => param.Format).ToArray();

        var payloadLen = 4 + portalBytes.Length + 4 + stmtBytes.Length;
        payloadLen += 2 + paramFormats.Length * 2;
        payloadLen += 2 + 2;
        foreach (var param in parameters)
        {
            payloadLen += 4;
            if (!param.IsNull && param.Data != null)
            {
                payloadLen += param.Data.Length;
            }
        }
        payloadLen += 2 + resultFormats.Count * 2;

        var payload = new byte[payloadLen];
        var offset = 0;
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(offset, 4), (uint)portalBytes.Length);
        offset += 4;
        Buffer.BlockCopy(portalBytes, 0, payload, offset, portalBytes.Length);
        offset += portalBytes.Length;
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(offset, 4), (uint)stmtBytes.Length);
        offset += 4;
        Buffer.BlockCopy(stmtBytes, 0, payload, offset, stmtBytes.Length);
        offset += stmtBytes.Length;
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), (ushort)paramFormats.Length);
        offset += 2;
        foreach (var fmt in paramFormats)
        {
            BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), fmt);
            offset += 2;
        }
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), (ushort)parameters.Count);
        offset += 2;
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), 0);
        offset += 2;
        foreach (var param in parameters)
        {
            if (param.IsNull)
            {
                BinaryPrimitives.WriteInt32LittleEndian(payload.AsSpan(offset, 4), -1);
                offset += 4;
                continue;
            }
            var data = param.Data ?? Array.Empty<byte>();
            BinaryPrimitives.WriteInt32LittleEndian(payload.AsSpan(offset, 4), data.Length);
            offset += 4;
            Buffer.BlockCopy(data, 0, payload, offset, data.Length);
            offset += data.Length;
        }
        BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), (ushort)resultFormats.Count);
        offset += 2;
        foreach (var fmt in resultFormats)
        {
            BinaryPrimitives.WriteUInt16LittleEndian(payload.AsSpan(offset, 2), fmt);
            offset += 2;
        }
        return payload;
    }

    public static byte[] BuildDescribePayload(byte describeType, string name)
    {
        var nameBytes = Encoding.UTF8.GetBytes(name);
        var payload = new byte[8 + nameBytes.Length];
        payload[0] = describeType;
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(4, 4), (uint)nameBytes.Length);
        Buffer.BlockCopy(nameBytes, 0, payload, 8, nameBytes.Length);
        return payload;
    }

    public static byte[] BuildExecutePayload(string portalName, uint maxRows)
    {
        var portalBytes = Encoding.UTF8.GetBytes(portalName);
        var payload = new byte[4 + portalBytes.Length + 4];
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(0, 4), (uint)portalBytes.Length);
        Buffer.BlockCopy(portalBytes, 0, payload, 4, portalBytes.Length);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(4 + portalBytes.Length, 4), maxRows);
        return payload;
    }

    public static byte[] BuildClosePayload(byte closeType, string name)
    {
        var nameBytes = Encoding.UTF8.GetBytes(name);
        var payload = new byte[8 + nameBytes.Length];
        payload[0] = closeType;
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(4, 4), (uint)nameBytes.Length);
        Buffer.BlockCopy(nameBytes, 0, payload, 8, nameBytes.Length);
        return payload;
    }

    public static byte[] BuildCancelPayload(uint cancelType, uint targetSequence)
    {
        var payload = new byte[8];
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(0, 4), cancelType);
        BinaryPrimitives.WriteUInt32LittleEndian(payload.AsSpan(4, 4), targetSequence);
        return payload;
    }

    public static (byte Status, ulong TxnId, ulong Visibility) ParseReady(byte[] payload)
    {
        if (payload.Length < 20)
        {
            throw new InvalidOperationException("Ready truncated");
        }
        var status = payload[0];
        var txnId = BinaryPrimitives.ReadUInt64LittleEndian(payload.AsSpan(4, 8));
        var visibility = BinaryPrimitives.ReadUInt64LittleEndian(payload.AsSpan(12, 8));
        return (status, txnId, visibility);
    }

    public static (string Name, string Value) ParseParameterStatus(byte[] payload)
    {
        if (payload.Length < 8)
        {
            throw new InvalidOperationException("Parameter status truncated");
        }
        var offset = 0;
        var nameLen = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
        offset += 4;
        var name = Encoding.UTF8.GetString(payload, offset, (int)nameLen);
        offset += (int)nameLen;
        var valueLen = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
        offset += 4;
        var value = Encoding.UTF8.GetString(payload, offset, (int)valueLen);
        return (name, value);
    }

    public static List<uint> ParseParameterDescription(byte[] payload)
    {
        if (payload.Length < 4)
        {
            throw new InvalidOperationException("Parameter description truncated");
        }
        var count = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(0, 2));
        var offset = 4;
        var types = new List<uint>(count);
        for (var i = 0; i < count; i++)
        {
            if (offset + 4 > payload.Length)
            {
                throw new InvalidOperationException("Parameter description truncated");
            }
            types.Add(BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4)));
            offset += 4;
        }
        return types;
    }

    public static List<ColumnInfo> ParseRowDescription(byte[] payload)
    {
        if (payload.Length < 4)
        {
            throw new InvalidOperationException("Row description truncated");
        }
        var offset = 0;
        var count = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 4;
        var cols = new List<ColumnInfo>(count);
        for (var i = 0; i < count; i++)
        {
            var nameLen = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
            offset += 4;
            var name = Encoding.UTF8.GetString(payload, offset, (int)nameLen);
            offset += (int)nameLen;
            var tableOid = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
            offset += 4;
            var columnIndex = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
            offset += 2;
            var typeOid = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(offset, 4));
            offset += 4;
            var typeSize = BinaryPrimitives.ReadInt16LittleEndian(payload.AsSpan(offset, 2));
            offset += 2;
            var typeModifier = BinaryPrimitives.ReadInt32LittleEndian(payload.AsSpan(offset, 4));
            offset += 4;
            var format = payload[offset];
            offset += 1;
            var nullable = payload[offset] == 1;
            offset += 1;
            offset += 2;
            cols.Add(new ColumnInfo
            {
                Name = name,
                TableOid = tableOid,
                ColumnIndex = columnIndex,
                TypeOid = typeOid,
                TypeSize = typeSize,
                TypeModifier = typeModifier,
                Format = format,
                Nullable = nullable
            });
        }
        return cols;
    }

    public static List<ColumnValue> ParseDataRow(byte[] payload)
    {
        if (payload.Length < 4)
        {
            throw new InvalidOperationException("Row data truncated");
        }
        var offset = 0;
        var count = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var nullBytes = BinaryPrimitives.ReadUInt16LittleEndian(payload.AsSpan(offset, 2));
        offset += 2;
        var nullBitmap = payload.AsSpan(offset, nullBytes).ToArray();
        offset += nullBytes;
        var values = new List<ColumnValue>(count);
        for (var i = 0; i < count; i++)
        {
            var byteIndex = i / 8;
            var bitIndex = i % 8;
            var isNull = byteIndex < nullBitmap.Length && (nullBitmap[byteIndex] & (1 << bitIndex)) != 0;
            if (isNull)
            {
                values.Add(new ColumnValue { Data = null });
                continue;
            }
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

    public static (byte CommandType, ulong Rows, ulong LastId, string Tag) ParseCommandComplete(byte[] payload)
    {
        if (payload.Length < 20)
        {
            throw new InvalidOperationException("Command complete truncated");
        }
        var commandType = payload[0];
        var rows = BinaryPrimitives.ReadUInt64LittleEndian(payload.AsSpan(4, 8));
        var lastId = BinaryPrimitives.ReadUInt64LittleEndian(payload.AsSpan(12, 8));
        var tagBytes = payload.AsSpan(20);
        var nullIdx = tagBytes.IndexOf((byte)0);
        var tag = Encoding.UTF8.GetString(nullIdx >= 0 ? tagBytes.Slice(0, nullIdx) : tagBytes);
        return (commandType, rows, lastId, tag);
    }

    public static (string Severity, string SqlState, string Message, string Detail, string Hint) ParseErrorMessage(byte[] payload)
    {
        var offset = 0;
        var severity = string.Empty;
        var sqlState = string.Empty;
        var message = string.Empty;
        var detail = string.Empty;
        var hint = string.Empty;

        while (offset < payload.Length)
        {
            var field = payload[offset];
            offset += 1;
            if (field == 0)
            {
                break;
            }
            var start = offset;
            while (offset < payload.Length && payload[offset] != 0)
            {
                offset += 1;
            }
            if (offset >= payload.Length)
            {
                break;
            }
            var value = Encoding.UTF8.GetString(payload, start, offset - start);
            offset += 1;
            switch ((char)field)
            {
                case 'S':
                    severity = value;
                    break;
                case 'C':
                    sqlState = value;
                    break;
                case 'M':
                    message = value;
                    break;
                case 'D':
                    detail = value;
                    break;
                case 'H':
                    hint = value;
                    break;
            }
        }

        return (severity, sqlState, message, detail, hint);
    }
}
