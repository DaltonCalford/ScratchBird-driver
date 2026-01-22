using System.Net.Security;
using System.Net.Sockets;
using System.Security.Authentication;
using System.Security.Cryptography.X509Certificates;
using System.Text;

namespace ScratchBird.Data;

internal sealed class ProtocolClient
{
    private TcpClient? _client;
    private Stream? _stream;
    private byte[]? _sessionId;
    private bool _connected;

    public bool Connected => _connected;
    public byte[] SessionId => _sessionId ?? throw new InvalidOperationException("Not connected");

    public void Connect(ScratchBirdConfig config)
    {
        _client = new TcpClient();
        _client.NoDelay = true;
        _client.SendTimeout = config.SocketTimeoutMs > 0 ? config.SocketTimeoutMs : 0;
        _client.ReceiveTimeout = config.SocketTimeoutMs > 0 ? config.SocketTimeoutMs : 0;

        var connectTask = _client.ConnectAsync(config.Host, config.Port);
        if (!connectTask.Wait(config.ConnectTimeoutMs))
        {
            throw new ScratchBirdConnectionException("Connection timeout", "08001");
        }

        _stream = _client.GetStream();
        var sslMode = (config.SslMode ?? "prefer").ToLowerInvariant();
        if (sslMode != "disable")
        {
            var requireTls = sslMode is "require" or "verify-ca" or "verify-full";
            try
            {
                _stream = UpgradeToTls(_stream, config, sslMode);
            }
            catch (Exception ex)
            {
                if (sslMode is "allow" or "prefer")
                {
                    _stream = _client.GetStream();
                }
                else if (requireTls)
                {
                    throw new ScratchBirdConnectionException($"TLS handshake failed: {ex.Message}", "08001");
                }
            }
        }

        var connectMessage = ProtocolCodec.BuildConnectRequest(config.Database, config.ApplicationName, Environment.ProcessId);
        Send(connectMessage);

        var response = Receive();
        if (response.Type != MessageType.ConnectResponse)
        {
            throw new ScratchBirdConnectionException("Unexpected response to CONNECT_REQUEST", "08001");
        }
        var parsed = ProtocolCodec.ParseConnectResponse(response.Payload);
        if (!parsed.Success)
        {
            throw new ScratchBirdConnectionException(parsed.Error, "08001");
        }
        _sessionId = parsed.SessionId;
        Authenticate(config);
        _connected = true;
    }

    public QueryStream ExecuteQuery(string sql)
    {
        EnsureConnected();
        var message = ProtocolCodec.BuildQuery(SessionId, sql);
        Send(message);
        return new QueryStream(this);
    }

    public void Begin()
    {
        EnsureConnected();
        Send(ProtocolCodec.BuildBegin(SessionId));
        DrainUntilComplete();
    }

    public void Commit()
    {
        EnsureConnected();
        Send(ProtocolCodec.BuildCommit(SessionId));
        DrainUntilComplete();
    }

    public void Rollback()
    {
        EnsureConnected();
        Send(ProtocolCodec.BuildRollback(SessionId));
        DrainUntilComplete();
    }

    public void Close()
    {
        if (!_connected)
        {
            _client?.Close();
            return;
        }
        try
        {
            if (_sessionId != null)
            {
                Send(ProtocolCodec.BuildDisconnect(_sessionId));
            }
        }
        catch
        {
        }
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

    private void Authenticate(ScratchBirdConfig config)
    {
        if (string.IsNullOrEmpty(config.Username))
        {
            return;
        }
        var scram = new ScramClient(config.Username);
        var clientFirst = Encoding.UTF8.GetBytes(scram.ClientFirstMessage());
        Send(ProtocolCodec.BuildAuthRequest(SessionId, config.Username, AuthMethod.ScramSha256, clientFirst));

        var response = Receive();
        if (response.Type != MessageType.AuthResponse)
        {
            throw new ScratchBirdAuthException("Unexpected auth response", "28000");
        }
        var parsed = ProtocolCodec.ParseAuthResponse(response.Payload);
        if (parsed.Status != AuthStatus.Continue)
        {
            throw new ScratchBirdAuthException(parsed.Error, "28000");
        }
        var serverFirst = Encoding.UTF8.GetString(parsed.Extra);
        var clientFinal = scram.HandleServerFirst(config.Password, serverFirst);
        Send(ProtocolCodec.BuildAuthRequest(SessionId, config.Username, AuthMethod.ScramSha256, Encoding.UTF8.GetBytes(clientFinal)));

        response = Receive();
        if (response.Type != MessageType.AuthResponse)
        {
            throw new ScratchBirdAuthException("Unexpected SCRAM final", "28000");
        }
        parsed = ProtocolCodec.ParseAuthResponse(response.Payload);
        if (parsed.Status != AuthStatus.Ok)
        {
            throw new ScratchBirdAuthException(parsed.Error, "28000");
        }
        if (parsed.Extra.Length > 0)
        {
            scram.VerifyServerFinal(Encoding.UTF8.GetString(parsed.Extra));
        }
    }

    private void DrainUntilComplete()
    {
        while (true)
        {
            var msg = Receive();
            if (msg.Type == MessageType.QueryError)
            {
                throw BuildQueryException(msg.Payload);
            }
            if (msg.Type == MessageType.CommandComplete || msg.Type == MessageType.EndOfResults)
            {
                return;
            }
        }
    }

    private ProtocolMessage Receive()
    {
        if (_stream == null)
        {
            throw new InvalidOperationException("No active stream");
        }
        var header = ReadExact(12);
        var (type, flags, length) = ProtocolMessage.ParseHeader(header);
        var payload = length > 0 ? ReadExact(length) : Array.Empty<byte>();
        return new ProtocolMessage(type, payload, flags);
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

    private void Send(ProtocolMessage message)
    {
        if (_stream == null)
        {
            throw new InvalidOperationException("No active stream");
        }
        var data = message.ToBytes();
        _stream.Write(data, 0, data.Length);
        _stream.Flush();
    }

    private ScratchBirdException BuildQueryException(byte[] payload)
    {
        var parsed = ProtocolCodec.ParseQueryError(payload);
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
        var cert = LoadClientCertificate(config.SslCert, config.SslKey);
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

    private X509Certificate2? LoadClientCertificate(string? certPath, string? keyPath)
    {
        if (string.IsNullOrEmpty(certPath))
        {
            return null;
        }

        if (!string.IsNullOrEmpty(keyPath))
        {
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
        private long _rowCountHint = -1;

        public QueryStream(ProtocolClient client)
        {
            _client = client;
        }

        public IReadOnlyList<ColumnInfo> Columns => _columns;
        public long RowsAffected => _rowsAffected >= 0 ? _rowsAffected : _rowCountHint;
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
                switch (msg.Type)
                {
                    case MessageType.QueryError:
                        throw _client.BuildQueryException(msg.Payload);
                    case MessageType.QueryResult:
                    {
                        var parsed = ProtocolCodec.ParseQueryResult(msg.Payload);
                        _rowCountHint = parsed.RowCount;
                        break;
                    }
                    case MessageType.RowDescription:
                        _columns = ProtocolCodec.ParseRowDescription(msg.Payload);
                        break;
                    case MessageType.RowData:
                    {
                        var values = ProtocolCodec.ParseRowData(msg.Payload);
                        var row = new object?[values.Count];
                        for (var i = 0; i < values.Count; i++)
                        {
                            var type = i < _columns.Count ? _columns[i].WireType : WireType.Unknown;
                            row[i] = TypeDecoder.Decode(type, values[i].Data);
                        }
                        return row;
                    }
                    case MessageType.CommandComplete:
                    {
                        var parsed = ProtocolCodec.ParseCommandComplete(msg.Payload);
                        _command = parsed.Tag;
                        _rowsAffected = parsed.RowsAffected;
                        break;
                    }
                    case MessageType.EndOfResults:
                        _done = true;
                        return null;
                }
            }
        }
    }
}
