// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
using System.Buffers.Binary;
using System.IO;
using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;

namespace ScratchBird.Data;

internal sealed class ProtocolClient
{
    private const uint QueryFlagBinaryResult = 0x04;
    private const uint ManagerProtocolMagic = 0x42444253;
    private const ushort ManagerProtocolVersion = 0x0101;
    private const ushort McpProtocolVersion = 0x0100;
    private const int ManagerHeaderSize = 12;
    private const int ManagerMaxPayloadSize = 16 * 1024 * 1024;

    private const byte McpMsgConnectResponse = 0x02;
    private const byte McpMsgAuthChallenge = 0x12;
    private const byte McpMsgAuthResponse = 0x11;
    private const byte McpMsgStatusResponse = 0x64;
    private const byte McpMsgHello = 0x65;
    private const byte McpMsgAuthStart = 0x66;
    private const byte McpMsgAuthContinue = 0x67;
    private const byte McpMsgDbConnect = 0x69;
    private const byte McpAuthMethodToken = 4;
    private sealed record NotificationMessage(uint ProcessId, string Channel, byte[] Payload, char? ChangeType, ulong? RowId);

    private TcpClient? _client;
    private Stream? _stream;
    private byte[] _attachmentId = new byte[16];
    private ulong _txnId;
    private uint _sequence;
    private uint _lastQuerySequence;
    private bool _connected;
    private readonly Dictionary<string, string> _parameters = new();
    private readonly List<Action<NotificationMessage>> _notificationHandlers = new();
    private (uint Format, ulong PlanningTimeUs, ulong EstimatedRows, ulong EstimatedCost, byte[] Plan)? _lastPlan;
    private (ulong Hash, uint Version, byte[] Bytecode)? _lastSblr;
    private ScratchBirdConfig? _config;

    public bool Connected => _connected;

    public void Connect(ScratchBirdConfig config)
    {
        config.Protocol = ScratchBirdConfig.NormalizeNativeProtocol(config.Protocol);
        config.FrontDoorMode = ScratchBirdConfig.NormalizeFrontDoorMode(config.FrontDoorMode);
        if (string.IsNullOrWhiteSpace(config.Username) || string.IsNullOrWhiteSpace(config.Database))
        {
            throw new ScratchBirdConnectionException("Username and database are required", "08001");
        }
        if (!config.BinaryTransfer)
        {
            throw new ScratchBirdNotSupportedException("binary_transfer=false is not supported", "0A000");
        }
        if (string.Equals(config.Compression, "zstd", StringComparison.OrdinalIgnoreCase))
        {
            throw new ScratchBirdNotSupportedException("compression=zstd is not supported", "0A000");
        }

        _client = new TcpClient { NoDelay = true };
        _client.SendTimeout = config.SocketTimeoutMs > 0 ? config.SocketTimeoutMs : 0;
        _client.ReceiveTimeout = config.SocketTimeoutMs > 0 ? config.SocketTimeoutMs : 0;

        var connectTask = _client.ConnectAsync(config.Host, config.Port);
        if (!connectTask.Wait(config.ConnectTimeoutMs))
        {
            throw new ScratchBirdConnectionException("Connection timeout", "08001");
        }

        _stream = _client.GetStream();
        var sslMode = (config.SslMode ?? "require").ToLowerInvariant();
        if (sslMode == "disable")
        {
            throw new ScratchBirdConnectionException("TLS is required for ScratchBird connections", "08001");
        }

        _stream = UpgradeToTls(_stream, config, sslMode);
        _config = config;
        if (string.Equals(config.FrontDoorMode, "manager_proxy", StringComparison.OrdinalIgnoreCase))
        {
            PerformManagerConnect(config);
        }
        Handshake(config);
        _connected = true;
    }

    public QueryStream ExecuteQuery(string sql)
    {
        return ExecuteQuery(sql, Array.Empty<ScratchBirdParameter>(), 0, 0);
    }

    public QueryStream ExecuteQuery(string sql, IReadOnlyList<ScratchBirdParameter> parameters, int timeoutMs, int maxRows)
    {
        EnsureConnected();
        if (parameters.Count == 0)
        {
            SendSimpleQuery(sql, timeoutMs, maxRows);
        }
        else
        {
            SendExtendedQuery(sql, parameters, maxRows);
        }
        return new QueryStream(this, timeoutMs, maxRows);
    }

    public void Begin()
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildTxnBeginPayload(0, 0, 0, ProtocolConstants.IsolationReadCommitted, 0, 0, 0, 0);
        SendMessage(MessageType.TXN_BEGIN, payload, 0, false);
        DrainUntilReady();
    }

    public void Commit()
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildTxnCommitPayload(0);
        SendMessage(MessageType.TXN_COMMIT, payload, 0, false);
        DrainUntilReady();
    }

    public void Rollback()
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildTxnRollbackPayload(0);
        SendMessage(MessageType.TXN_ROLLBACK, payload, 0, false);
        DrainUntilReady();
    }

    public void Savepoint(string name)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildTxnSavepointPayload(name);
        SendMessage(MessageType.TXN_SAVEPOINT, payload, 0, false);
        DrainUntilReady();
    }

    public void ReleaseSavepoint(string name)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildTxnReleasePayload(name);
        SendMessage(MessageType.TXN_RELEASE, payload, 0, false);
        DrainUntilReady();
    }

    public void RollbackToSavepoint(string name)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildTxnRollbackToPayload(name);
        SendMessage(MessageType.TXN_ROLLBACK_TO, payload, 0, false);
        DrainUntilReady();
    }

    public void SetOption(string name, string value)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildSetOptionPayload(name, value);
        SendMessage(MessageType.SET_OPTION, payload, 0, false);
        DrainUntilReady();
    }

    public void Ping()
    {
        EnsureConnected();
        SendMessage(MessageType.PING, Array.Empty<byte>(), 0, false);
        while (true)
        {
            var msg = Receive();
            if (HandleAsyncMessage(msg))
            {
                continue;
            }
            switch ((MessageType)msg.Header.Type)
            {
                case MessageType.PONG:
                    return;
                case MessageType.READY:
                {
                    var ready = ProtocolCodec.ParseReady(msg.Payload);
                    _txnId = ready.TxnId;
                    return;
                }
                case MessageType.ERROR:
                    throw BuildQueryException(msg.Payload);
            }
        }
    }

    public void Subscribe(byte subscribeType, string channel, string filterExpr = "")
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildSubscribePayload(subscribeType, channel, filterExpr);
        SendMessage(MessageType.SUBSCRIBE, payload, 0, false);
        DrainUntilReady();
    }

    public void Unsubscribe(string channel)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildUnsubscribePayload(channel);
        SendMessage(MessageType.UNSUBSCRIBE, payload, 0, false);
        DrainUntilReady();
    }

    public QueryStream ExecuteSblr(ulong hash, byte[]? bytecode, IReadOnlyList<ScratchBirdParameter> parameters, int timeoutMs, int maxRows)
    {
        EnsureConnected();
        var paramValues = new List<ParamValue>();
        foreach (var parameter in parameters)
        {
            var encoded = TypeDecoder.EncodeParameter(parameter);
            paramValues.Add(encoded.Param);
        }
        var payload = ProtocolCodec.BuildSblrExecutePayload(hash, bytecode, paramValues);
        SendMessage(MessageType.SBLR_EXECUTE, payload, 0, false);
        SendMessage(MessageType.SYNC, Array.Empty<byte>(), 0, false);
        return new QueryStream(this, timeoutMs, maxRows);
    }

    public void StreamControl(byte controlType, uint windowSize, uint timeoutMs)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildStreamControlPayload(controlType, windowSize, timeoutMs);
        SendMessage(MessageType.STREAM_CONTROL, payload, 0, false);
    }

    public void AttachCreate(string emulationMode, string dbName)
    {
        EnsureConnected();
        var payload = ProtocolCodec.BuildAttachCreatePayload(emulationMode, dbName);
        SendMessage(MessageType.ATTACH_CREATE, payload, 0, false);
        DrainUntilReady();
    }

    public void AttachDetach()
    {
        EnsureConnected();
        SendMessage(MessageType.ATTACH_DETACH, Array.Empty<byte>(), 0, false);
        DrainUntilReady();
    }

    public QueryStream AttachList()
    {
        EnsureConnected();
        SendMessage(MessageType.ATTACH_LIST, Array.Empty<byte>(), 0, false);
        SendMessage(MessageType.SYNC, Array.Empty<byte>(), 0, false);
        return new QueryStream(this, 0, 0);
    }

    public void OnNotification(Action<uint, string, byte[], char?, ulong?> handler)
    {
        _notificationHandlers.Add(msg => handler(msg.ProcessId, msg.Channel, msg.Payload, msg.ChangeType, msg.RowId));
    }

    public (uint Format, ulong PlanningTimeUs, ulong EstimatedRows, ulong EstimatedCost, byte[] Plan)? LastPlan => _lastPlan;
    public (ulong Hash, uint Version, byte[] Bytecode)? LastSblr => _lastSblr;

    public void Cancel()
    {
        if (!_connected)
        {
            return;
        }
        SendMessage(MessageType.CANCEL, ProtocolCodec.BuildCancelPayload(0, _lastQuerySequence), ProtocolConstants.MsgFlagUrgent, false);
    }

    public void Close()
    {
        _stream?.Dispose();
        _client?.Close();
        _connected = false;
    }

    private void EnsureConnected()
    {
        if (!_connected || _stream == null)
        {
            throw new InvalidOperationException("Connection is not open");
        }
    }

    private void Handshake(ScratchBirdConfig config)
    {
        var parameters = new Dictionary<string, string>
        {
            ["database"] = config.Database,
            ["user"] = config.Username
        };
        if (!string.IsNullOrWhiteSpace(config.Role))
        {
            parameters["role"] = config.Role;
        }
        if (!string.IsNullOrWhiteSpace(config.ApplicationName))
        {
            parameters["application_name"] = config.ApplicationName;
        }

        var features = 0UL;
        if (string.Equals(config.Compression, "zstd", StringComparison.OrdinalIgnoreCase))
        {
            features |= ProtocolConstants.FeatureCompression;
        }
        if (config.BinaryTransfer)
        {
            features |= ProtocolConstants.FeatureStreaming;
        }

        var startup = ProtocolCodec.BuildStartupPayload(features, parameters);
        SendMessage(MessageType.STARTUP, startup, 0, true);

        ScramClient? scram = null;

        while (true)
        {
            var msg = Receive();
            if (HandleAsyncMessage(msg))
            {
                continue;
            }
            switch ((MessageType)msg.Header.Type)
            {
                case MessageType.NEGOTIATE_VERSION:
                    continue;
                case MessageType.AUTH_REQUEST:
                {
                    var parsed = ProtocolCodec.ParseAuthRequest(msg.Payload);
                    if (parsed.Method == AuthMethod.OK)
                    {
                        continue;
                    }
                    if (parsed.Method == AuthMethod.PASSWORD)
                    {
                        var passwordBytes = Encoding.UTF8.GetBytes(config.Password ?? string.Empty);
                        SendMessage(MessageType.AUTH_RESPONSE, passwordBytes, 0, true);
                        continue;
                    }
                    if (parsed.Method == AuthMethod.SCRAM_SHA_256)
                    {
                        scram ??= new ScramClient(config.Username);
                        var clientFirst = Encoding.UTF8.GetBytes(scram.ClientFirstMessage());
                        SendMessage(MessageType.AUTH_RESPONSE, clientFirst, 0, true);
                        continue;
                    }
                    throw new ScratchBirdAuthException("Unsupported auth method", "28000");
                }
                case MessageType.AUTH_CONTINUE:
                {
                    var parsed = ProtocolCodec.ParseAuthContinue(msg.Payload);
                    if (parsed.Method != AuthMethod.SCRAM_SHA_256 || scram == null)
                    {
                        throw new ScratchBirdAuthException("Unsupported auth continue", "28000");
                    }
                    var serverFirst = Encoding.UTF8.GetString(parsed.Data);
                    var clientFinal = scram.HandleServerFirst(config.Password ?? string.Empty, serverFirst);
                    SendMessage(MessageType.AUTH_RESPONSE, Encoding.UTF8.GetBytes(clientFinal), 0, true);
                    continue;
                }
                case MessageType.AUTH_OK:
                {
                    var parsed = ProtocolCodec.ParseAuthOk(msg.Payload);
                    SetAttachment(msg.Header.AttachmentId, msg.Header.TxnId);
                    if (scram != null && parsed.ServerInfo.Length > 0)
                    {
                        var serverFinal = Encoding.UTF8.GetString(parsed.ServerInfo);
                        if (serverFinal.StartsWith("v=", StringComparison.Ordinal))
                        {
                            scram.VerifyServerFinal(serverFinal);
                        }
                    }
                    continue;
                }
                case MessageType.PARAMETER_STATUS:
                {
                    var status = ProtocolCodec.ParseParameterStatus(msg.Payload);
                    _parameters[status.Name] = status.Value;
                    continue;
                }
                case MessageType.READY:
                {
                    var ready = ProtocolCodec.ParseReady(msg.Payload);
                    _txnId = ready.TxnId;
                    return;
                }
                case MessageType.ERROR:
                    throw BuildQueryException(msg.Payload);
                default:
                    continue;
            }
        }
    }

    private void SendSimpleQuery(string sql, int timeoutMs, int maxRows)
    {
        var flags = ConfigBinaryTransfer() ? QueryFlagBinaryResult : 0;
        var payload = ProtocolCodec.BuildQueryPayload(sql, flags, (uint)Math.Max(0, maxRows), (uint)Math.Max(0, timeoutMs));
        _lastQuerySequence = SendMessage(MessageType.QUERY, payload, 0, false);
    }

    private void SendExtendedQuery(string sql, IReadOnlyList<ScratchBirdParameter> parameters, int maxRows)
    {
        var paramValues = new List<ParamValue>(parameters.Count);
        var paramTypes = new List<uint>(parameters.Count);
        foreach (var param in parameters)
        {
            var encoded = TypeDecoder.EncodeParameter(param);
            paramValues.Add(encoded.Param);
            paramTypes.Add(encoded.Oid);
        }
        var parsePayload = ProtocolCodec.BuildParsePayload(string.Empty, sql, paramTypes);
        SendMessage(MessageType.PARSE, parsePayload, 0, false);
        var described = DescribeStatement(string.Empty);
        if (described >= 0 && described != paramTypes.Count)
        {
            throw new ScratchBirdSyntaxException("parameter count mismatch", "07001");
        }

        var resultFormats = ConfigBinaryTransfer() ? new[] { TypeDecoder.FormatBinary } : Array.Empty<ushort>();
        var bindPayload = ProtocolCodec.BuildBindPayload(string.Empty, string.Empty, paramValues, resultFormats);
        SendMessage(MessageType.BIND, bindPayload, 0, false);

        var execPayload = ProtocolCodec.BuildExecutePayload(string.Empty, (uint)Math.Max(0, maxRows));
        _lastQuerySequence = SendMessage(MessageType.EXECUTE, execPayload, 0, false);
        if (maxRows <= 0)
        {
            SendMessage(MessageType.SYNC, Array.Empty<byte>(), 0, false);
        }
    }

    private int DescribeStatement(string name)
    {
        var payload = ProtocolCodec.BuildDescribePayload((byte)'S', name);
        SendMessage(MessageType.DESCRIBE, payload, 0, false);
        SendMessage(MessageType.SYNC, Array.Empty<byte>(), 0, false);
        var paramCount = -1;
        while (true)
        {
            var msg = Receive();
            if (HandleAsyncMessage(msg))
            {
                continue;
            }
            switch ((MessageType)msg.Header.Type)
            {
                case MessageType.PARAMETER_DESCRIPTION:
                    paramCount = ProtocolCodec.ParseParameterDescription(msg.Payload).Count;
                    continue;
                case MessageType.ERROR:
                    throw BuildQueryException(msg.Payload);
                case MessageType.READY:
                    var ready = ProtocolCodec.ParseReady(msg.Payload);
                    _txnId = ready.TxnId;
                    return paramCount;
                default:
                    continue;
            }
        }
    }

    private bool ConfigBinaryTransfer()
    {
        return _config?.BinaryTransfer ?? true;
    }

    private bool HandleAsyncMessage(ProtocolMessage msg)
    {
        switch ((MessageType)msg.Header.Type)
        {
            case MessageType.PARAMETER_STATUS:
            {
                var status = ProtocolCodec.ParseParameterStatus(msg.Payload);
                _parameters[status.Name] = status.Value;
                if (status.Name == "attachment_id" && TryParseUuidBytes(status.Value, out var attachment))
                {
                    _attachmentId = attachment;
                }
                if (status.Name == "current_txn_id" && TryParseUInt64(status.Value, out var txnId))
                {
                    _txnId = txnId;
                }
                return true;
            }
            case MessageType.NOTIFICATION:
            {
                var notice = ProtocolCodec.ParseNotification(msg.Payload);
                foreach (var handler in _notificationHandlers)
                {
                    handler(new NotificationMessage(notice.ProcessId, notice.Channel, notice.Payload, notice.ChangeType, notice.RowId));
                }
                return true;
            }
            case MessageType.QUERY_PLAN:
            {
                _lastPlan = ProtocolCodec.ParseQueryPlan(msg.Payload);
                return true;
            }
            case MessageType.SBLR_COMPILED:
            {
                _lastSblr = ProtocolCodec.ParseSblrCompiled(msg.Payload);
                return true;
            }
            default:
                return false;
        }
    }

    private void DrainUntilReady()
    {
        while (true)
        {
            var msg = Receive();
            if (HandleAsyncMessage(msg))
            {
                continue;
            }
            switch ((MessageType)msg.Header.Type)
            {
                case MessageType.READY:
                {
                    var ready = ProtocolCodec.ParseReady(msg.Payload);
                    _txnId = ready.TxnId;
                    return;
                }
                case MessageType.ERROR:
                    throw BuildQueryException(msg.Payload);
            }
        }
    }

    private static bool TryParseUuidBytes(string value, out byte[] bytes)
    {
        bytes = Array.Empty<byte>();
        var hex = value.Replace("-", string.Empty).Trim();
        if (hex.Length != 32)
        {
            return false;
        }
        try
        {
            bytes = Convert.FromHexString(hex);
            return bytes.Length == 16;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private static bool TryParseUInt64(string value, out ulong parsed)
    {
        return ulong.TryParse(value.Trim(), out parsed);
    }

    private static byte[] BuildLengthPrefixedString(string value)
    {
        var bytes = Encoding.UTF8.GetBytes(value);
        var payload = new byte[4 + bytes.Length];
        BitConverter.GetBytes((uint)bytes.Length).CopyTo(payload, 0);
        bytes.CopyTo(payload, 4);
        return payload;
    }

    private void SendManagerFrame(byte msgType, byte[] payload)
    {
        if (_stream == null)
        {
            throw new InvalidOperationException("No active stream");
        }
        var frame = new byte[ManagerHeaderSize + payload.Length];
        BinaryPrimitives.WriteUInt32LittleEndian(frame.AsSpan(0, 4), ManagerProtocolMagic);
        BinaryPrimitives.WriteUInt16LittleEndian(frame.AsSpan(4, 2), ManagerProtocolVersion);
        frame[6] = msgType;
        frame[7] = 0;
        BinaryPrimitives.WriteUInt32LittleEndian(frame.AsSpan(8, 4), (uint)payload.Length);
        if (payload.Length > 0)
        {
            Buffer.BlockCopy(payload, 0, frame, ManagerHeaderSize, payload.Length);
        }
        _stream.Write(frame, 0, frame.Length);
        _stream.Flush();
    }

    private (byte Type, byte[] Payload) ReceiveManagerFrame()
    {
        var header = ReadExact(ManagerHeaderSize);
        var magic = BinaryPrimitives.ReadUInt32LittleEndian(header.AsSpan(0, 4));
        if (magic != ManagerProtocolMagic)
        {
            throw new ScratchBirdConnectionException("Manager frame magic mismatch", "08P01");
        }
        var version = BinaryPrimitives.ReadUInt16LittleEndian(header.AsSpan(4, 2));
        if (version != ManagerProtocolVersion)
        {
            throw new ScratchBirdConnectionException("Manager frame version mismatch", "08P01");
        }
        var type = header[6];
        var length = BinaryPrimitives.ReadUInt32LittleEndian(header.AsSpan(8, 4));
        if (length > ManagerMaxPayloadSize)
        {
            throw new ScratchBirdConnectionException("Manager payload too large", "08P01");
        }
        var payload = length > 0 ? ReadExact((int)length) : Array.Empty<byte>();
        return (type, payload);
    }

    private void PerformManagerConnect(ScratchBirdConfig config)
    {
        if (string.IsNullOrEmpty(config.ManagerAuthToken))
        {
            throw new ScratchBirdConnectionException("manager_proxy mode requires manager_auth_token", "08001");
        }
        var managerUser = !string.IsNullOrEmpty(config.ManagerUsername)
            ? config.ManagerUsername
            : (!string.IsNullOrEmpty(config.Username) ? config.Username : "admin");
        var managerDatabase = !string.IsNullOrEmpty(config.ManagerDatabase) ? config.ManagerDatabase : config.Database;
        var managerProfile = !string.IsNullOrEmpty(config.ManagerConnectionProfile) ? config.ManagerConnectionProfile : "native_v3";
        var managerIntent = !string.IsNullOrEmpty(config.ManagerClientIntent) ? config.ManagerClientIntent : "native_v3";

        var helloPayload = new byte[4];
        BinaryPrimitives.WriteUInt16LittleEndian(helloPayload.AsSpan(0, 2), McpProtocolVersion);
        BinaryPrimitives.WriteUInt16LittleEndian(helloPayload.AsSpan(2, 2), config.ManagerClientFlags);
        SendManagerFrame(McpMsgHello, helloPayload);
        var (msgType, _) = ReceiveManagerFrame();
        if (msgType != McpMsgStatusResponse)
        {
            throw new ScratchBirdConnectionException("Expected MCP hello status response", "08P01");
        }

        using var authStart = new MemoryStream();
        authStart.Write(BuildLengthPrefixedString(managerUser));
        authStart.WriteByte(McpAuthMethodToken);
        if (config.ManagerAuthFastPath)
        {
            var tokenBytes = Encoding.UTF8.GetBytes(config.ManagerAuthToken);
            authStart.Write(BitConverter.GetBytes((uint)tokenBytes.Length));
            authStart.Write(tokenBytes);
        }
        else
        {
            authStart.Write(BitConverter.GetBytes(0U));
        }
        SendManagerFrame(McpMsgAuthStart, authStart.ToArray());
        (msgType, var payload) = ReceiveManagerFrame();
        if (msgType == McpMsgAuthChallenge)
        {
            var tokenBytes = Encoding.UTF8.GetBytes(config.ManagerAuthToken);
            using var authContinue = new MemoryStream();
            authContinue.Write(BitConverter.GetBytes((uint)tokenBytes.Length));
            authContinue.Write(tokenBytes);
            SendManagerFrame(McpMsgAuthContinue, authContinue.ToArray());
            (msgType, payload) = ReceiveManagerFrame();
        }
        if (msgType != McpMsgAuthResponse)
        {
            throw new ScratchBirdConnectionException("Expected MCP auth response", "08P01");
        }
        if (payload.Length < 1 + 4 + 256)
        {
            throw new ScratchBirdConnectionException("Truncated MCP auth response", "08P01");
        }
        if (payload[0] != 0)
        {
            var err = Encoding.UTF8.GetString(payload, 5, 256).TrimEnd('\0');
            throw new ScratchBirdAuthException(string.IsNullOrEmpty(err) ? "MCP authentication failed" : err, "28000");
        }

        var nonce = new byte[16];
        RandomNumberGenerator.Fill(nonce);
        using var dbConnect = new MemoryStream();
        dbConnect.Write(Encoding.ASCII.GetBytes("MCP1"));
        dbConnect.Write(BuildLengthPrefixedString(managerDatabase));
        dbConnect.Write(BuildLengthPrefixedString(managerProfile));
        dbConnect.Write(BuildLengthPrefixedString(managerIntent));
        dbConnect.Write(BitConverter.GetBytes((ushort)nonce.Length));
        dbConnect.Write(nonce);
        SendManagerFrame(McpMsgDbConnect, dbConnect.ToArray());
        (msgType, payload) = ReceiveManagerFrame();
        if (msgType != McpMsgConnectResponse)
        {
            throw new ScratchBirdConnectionException("Expected MCP connect response", "08P01");
        }
        if (payload.Length < 1 + 2 + 2 + 16 + 64 + 32)
        {
            throw new ScratchBirdConnectionException("Truncated MCP connect response", "08P01");
        }
        if (payload[0] != 0)
        {
            var err = "MCP database connect failed";
            var errOffset = 1 + 2 + 2 + 16 + 64 + 32;
            if (payload.Length >= errOffset + 4)
            {
                var errLen = BinaryPrimitives.ReadUInt32LittleEndian(payload.AsSpan(errOffset, 4));
                if (payload.Length >= errOffset + 4 + errLen)
                {
                    err = Encoding.UTF8.GetString(payload, errOffset + 4, (int)errLen);
                }
            }
            throw new ScratchBirdAuthException(err, "28000");
        }
    }

    private ProtocolMessage Receive()
    {
        var headerBytes = ReadExact(ProtocolConstants.HeaderSize);
        var header = ProtocolMessage.ParseHeader(headerBytes);
        var payload = header.Length > 0 ? ReadExact((int)header.Length) : Array.Empty<byte>();
        return new ProtocolMessage(header, payload);
    }

    private byte[] ReadExact(int length)
    {
        if (_stream == null)
        {
            throw new InvalidOperationException("No active stream");
        }
        var buffer = new byte[length];
        var offset = 0;
        while (offset < length)
        {
            var read = _stream.Read(buffer, offset, length - offset);
            if (read <= 0)
            {
                throw new ScratchBirdConnectionException("Connection closed", "08006");
            }
            offset += read;
        }
        return buffer;
    }

    private uint SendMessage(MessageType type, byte[] payload, byte flags, bool forceZero)
    {
        if (_stream == null)
        {
            throw new InvalidOperationException("No active stream");
        }
        var sequence = _sequence++;
        var attachmentId = forceZero ? new byte[16] : _attachmentId;
        var txnId = forceZero ? 0UL : _txnId;
        var header = new MessageHeader((byte)type, flags, (uint)payload.Length, sequence, attachmentId, txnId);
        var message = new ProtocolMessage(header, payload);
        var data = message.ToBytes();
        _stream.Write(data, 0, data.Length);
        _stream.Flush();
        return sequence;
    }

    private void SetAttachment(byte[] attachmentId, ulong txnId)
    {
        _attachmentId = attachmentId;
        _txnId = txnId;
    }

    private ScratchBirdException BuildQueryException(byte[] payload)
    {
        var parsed = ProtocolCodec.ParseErrorMessage(payload);
        var message = parsed.Message;
        if (!string.IsNullOrEmpty(parsed.Detail))
        {
            message += $"\nDETAIL: {parsed.Detail}";
        }
        if (!string.IsNullOrEmpty(parsed.Hint))
        {
            message += $"\nHINT: {parsed.Hint}";
        }
        return ScratchBirdSqlStateMapper.Create(message, parsed.SqlState, parsed.Detail, parsed.Hint);
    }

    private Stream UpgradeToTls(Stream stream, ScratchBirdConfig config, string sslMode)
    {
        var cert = LoadClientCertificate(config.SslCert, config.SslKey, config.SslPassword);
        var certs = new X509CertificateCollection();
        if (cert != null)
        {
            certs.Add(cert);
        }

        var options = new SslClientAuthenticationOptions
        {
            TargetHost = config.Host,
            EnabledSslProtocols = SslProtocols.Tls13,
            ClientCertificates = certs,
            CertificateRevocationCheckMode = X509RevocationMode.NoCheck,
            RemoteCertificateValidationCallback = (sender, certificate, chain, errors) =>
            {
                if (sslMode == "verify-full")
                {
                    return errors == SslPolicyErrors.None;
                }
                if (sslMode == "verify-ca")
                {
                    return errors == SslPolicyErrors.None || errors == SslPolicyErrors.RemoteCertificateNameMismatch;
                }
                return true;
            }
        };

        if (!string.IsNullOrEmpty(config.SslRootCert))
        {
            var ca = new X509Certificate2(config.SslRootCert);
            options.CertificateChainPolicy = new X509ChainPolicy
            {
                TrustMode = X509ChainTrustMode.CustomRootTrust,
                CustomTrustStore = { ca }
            };
        }

        var sslStream = new SslStream(stream, false, options.RemoteCertificateValidationCallback);
        sslStream.AuthenticateAsClient(options);
        return sslStream;
    }

    private X509Certificate2? LoadClientCertificate(string? certPath, string? keyPath, string? password)
    {
        if (string.IsNullOrEmpty(certPath))
        {
            return null;
        }

        if (!string.IsNullOrEmpty(keyPath))
        {
            if (!string.IsNullOrEmpty(password))
            {
                return X509Certificate2.CreateFromEncryptedPemFile(certPath, keyPath, password);
            }
            return X509Certificate2.CreateFromPemFile(certPath, keyPath);
        }

        return new X509Certificate2(certPath);
    }

    internal sealed class QueryStream
    {
        private readonly ProtocolClient _client;
        private bool _done;
        private List<ColumnInfo> _columns = new();
        private long _rowsAffected = -1;
        private string _command = string.Empty;
        private readonly int _pageSize;

        private readonly CancellationTokenSource? _timeoutCts;

        public QueryStream(ProtocolClient client, int timeoutMs, int pageSize)
        {
            _client = client;
            _pageSize = Math.Max(0, pageSize);
            if (timeoutMs > 0)
            {
                _timeoutCts = new CancellationTokenSource(timeoutMs);
                _timeoutCts.Token.Register(() => _client.Cancel());
            }
        }

        public IReadOnlyList<ColumnInfo> Columns => _columns;
        public long RowsAffected => _rowsAffected;
        public string Command => _command;

        public object?[]? ReadNextRow()
        {
            if (_done)
            {
                return null;
            }

            while (true)
            {
                var msg = _client.Receive();
                if (_client.HandleAsyncMessage(msg))
                {
                    continue;
                }
                switch ((MessageType)msg.Header.Type)
                {
                    case MessageType.ERROR:
                        throw _client.BuildQueryException(msg.Payload);
                    case MessageType.ROW_DESCRIPTION:
                        _columns = ProtocolCodec.ParseRowDescription(msg.Payload);
                        break;
                    case MessageType.DATA_ROW:
                    {
                        var values = ProtocolCodec.ParseDataRow(msg.Payload);
                        var row = new object?[values.Count];
                        for (var i = 0; i < values.Count; i++)
                        {
                            var typeOid = i < _columns.Count ? _columns[i].TypeOid : 0;
                            var format = i < _columns.Count ? _columns[i].Format : (byte)TypeDecoder.FormatBinary;
                            row[i] = TypeDecoder.Decode(typeOid, values[i].Data, format);
                        }
                        return row;
                    }
                    case MessageType.COMMAND_COMPLETE:
                    {
                        var parsed = ProtocolCodec.ParseCommandComplete(msg.Payload);
                        _command = parsed.Tag;
                        _rowsAffected = (long)parsed.Rows;
                        break;
                    }
                    case MessageType.PORTAL_SUSPENDED:
                    {
                        var execPayload = ProtocolCodec.BuildExecutePayload(string.Empty, (uint)_pageSize);
                        _client.SendMessage(MessageType.EXECUTE, execPayload, 0, false);
                        break;
                    }
                    case MessageType.READY:
                    {
                        var ready = ProtocolCodec.ParseReady(msg.Payload);
                        _client._txnId = ready.TxnId;
                        _done = true;
                        _timeoutCts?.Cancel();
                        return null;
                    }
                    case MessageType.EMPTY_QUERY:
                        break;
                }
            }
        }
    }
}
