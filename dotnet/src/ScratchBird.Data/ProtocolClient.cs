using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;

namespace ScratchBird.Data;

internal sealed class ProtocolClient
{
    private const uint QueryFlagBinaryResult = 0x04;

    private TcpClient? _client;
    private Stream? _stream;
    private byte[] _attachmentId = new byte[16];
    private ulong _txnId;
    private uint _sequence;
    private uint _lastQuerySequence;
    private bool _connected;
    private readonly Dictionary<string, string> _parameters = new();
    private ScratchBirdConfig? _config;

    public bool Connected => _connected;

    public void Connect(ScratchBirdConfig config)
    {
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
    }

    public void Commit()
    {
    }

    public void Rollback()
    {
    }

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
        SendMessage(MessageType.SYNC, Array.Empty<byte>(), 0, false);
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
            switch ((MessageType)msg.Header.Type)
            {
                case MessageType.PARAMETER_DESCRIPTION:
                    paramCount = ProtocolCodec.ParseParameterDescription(msg.Payload).Count;
                    continue;
                case MessageType.PARAMETER_STATUS:
                    var status = ProtocolCodec.ParseParameterStatus(msg.Payload);
                    _parameters[status.Name] = status.Value;
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
                        _client.SendMessage(MessageType.SYNC, Array.Empty<byte>(), 0, false);
                        break;
                    }
                    case MessageType.PARAMETER_STATUS:
                    {
                        var status = ProtocolCodec.ParseParameterStatus(msg.Payload);
                        _client._parameters[status.Name] = status.Value;
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
