/*
 * ScratchBird JDBC Driver
 * Copyright (c) 2025 ScratchBird Project
 */
package com.scratchbird.jdbc;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.EOFException;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.security.KeyStore;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;

/**
 * Protocol handler for ScratchBird native wire protocol.
 */
public class SBProtocolHandler {

    private static final int PROTOCOL_MAGIC = 0x53425750;
    private static final int PROTOCOL_VERSION_MAJOR = 1;
    private static final int PROTOCOL_VERSION_MINOR = 1;
    private static final int HEADER_SIZE = 40;
    private static final int MAX_MESSAGE_SIZE = 1024 * 1024 * 1024;

    private static final byte MSG_STARTUP = 0x01;
    private static final byte MSG_AUTH_RESPONSE = 0x02;
    private static final byte MSG_QUERY = 0x03;
    private static final byte MSG_PARSE = 0x04;
    private static final byte MSG_BIND = 0x05;
    private static final byte MSG_DESCRIBE = 0x06;
    private static final byte MSG_EXECUTE = 0x07;
    private static final byte MSG_CLOSE = 0x08;
    private static final byte MSG_SYNC = 0x09;
    private static final byte MSG_FLUSH = 0x0A;
    private static final byte MSG_CANCEL = 0x0B;

    private static final byte MSG_AUTH_REQUEST = 0x40;
    private static final byte MSG_AUTH_OK = 0x41;
    private static final byte MSG_AUTH_CONTINUE = 0x42;
    private static final byte MSG_READY = 0x43;
    private static final byte MSG_ROW_DESCRIPTION = 0x44;
    private static final byte MSG_DATA_ROW = 0x45;
    private static final byte MSG_COMMAND_COMPLETE = 0x46;
    private static final byte MSG_EMPTY_QUERY = 0x47;
    private static final byte MSG_ERROR = 0x48;
    private static final byte MSG_NOTICE = 0x49;
    private static final byte MSG_PARSE_COMPLETE = 0x4A;
    private static final byte MSG_BIND_COMPLETE = 0x4B;
    private static final byte MSG_CLOSE_COMPLETE = 0x4C;
    private static final byte MSG_PORTAL_SUSPENDED = 0x4D;
    private static final byte MSG_NO_DATA = 0x4E;
    private static final byte MSG_PARAMETER_STATUS = 0x4F;
    private static final byte MSG_NEGOTIATE_VERSION = 0x56;
    private static final byte MSG_TXN_STATUS = 0x5C;
    private static final byte MSG_PONG = 0x5D;

    private static final int AUTH_OK = 0;
    private static final int AUTH_PASSWORD = 1;
    private static final int AUTH_SCRAM_SHA_256 = 3;

    private static final byte MSG_FLAG_URGENT = 0x08;

    private static final long FEATURE_STREAMING = 1L << 1;

    private static final int QUERY_FLAG_BINARY_RESULT = 0x04;

    private final SBConnectionProperties props;

    private Socket socket;
    private InputStream inputStream;
    private OutputStream outputStream;

    private boolean connected = false;
    private int networkTimeout = 0;
    private int sequence = 0;
    private byte[] attachmentId = new byte[16];
    private long txnId = 0;

    private final Map<String, String> serverParameters = new HashMap<>();
    private SBScramClient scramClient;

    public SBProtocolHandler(SBConnectionProperties props) {
        this.props = props;
    }

    public void connect() throws SQLException {
        try {
            socket = new Socket();
            socket.setTcpNoDelay(true);
            socket.setKeepAlive(props.isTcpKeepAlive());
            if (props.getSocketTimeout() > 0) {
                socket.setSoTimeout(props.getSocketTimeout() * 1000);
            }

            InetSocketAddress address = new InetSocketAddress(props.getHost(), props.getPort());
            socket.connect(address, props.getConnectTimeout() * 1000);

            String sslMode = props.getSslMode();
            if (sslMode == null || sslMode.isEmpty()) {
                sslMode = "require";
            }
            if ("disable".equalsIgnoreCase(sslMode)) {
                throw new SQLException("TLS is required for ScratchBird connections", "08001");
            }
            upgradeToSSL(sslMode);

            sendStartupMessage();
            handleAuthentication();
            connected = true;

        } catch (IOException e) {
            close();
            throw new SQLException("Failed to connect: " + e.getMessage(), "08001", e);
        }
    }

    public SBQueryResult execute(String sql) throws SQLException {
        return execute(sql, Collections.emptyList(), Collections.emptyList(), 0, 0);
    }

    public SBQueryResult execute(String sql, int maxRows, int timeoutMs) throws SQLException {
        return execute(sql, Collections.emptyList(), Collections.emptyList(), maxRows, timeoutMs);
    }

    public SBQueryResult execute(String sql, List<Object> params, List<Integer> paramTypes,
                                 int maxRows, int timeoutMs) throws SQLException {
        try {
            if (params == null || params.isEmpty()) {
                sendSimpleQuery(sql, maxRows, timeoutMs);
            } else {
                sendExtendedQuery(sql, params, paramTypes, maxRows);
            }
            return readQueryResult();
        } catch (IOException e) {
            throw new SQLException("Query execution failed: " + e.getMessage(), "08006", e);
        }
    }

    public void cancelCurrentQuery() throws SQLException {
        if (!connected) return;
        try {
            sendMessage(MSG_CANCEL, buildCancelPayload(0, 0), MSG_FLAG_URGENT, false);
        } catch (IOException e) {
            throw new SQLException("Failed to cancel query: " + e.getMessage(), "08006", e);
        }
    }

    public boolean isAlive(int timeout) {
        if (!connected || socket == null || socket.isClosed()) {
            return false;
        }
        try {
            int oldTimeout = socket.getSoTimeout();
            socket.setSoTimeout(timeout * 1000);
            try {
                sendMessage(MSG_SYNC, new byte[0], (byte) 0, false);
                while (true) {
                    ProtocolMessage msg = readMessage();
                    if (msg.type == MSG_READY) {
                        ReadyStatus ready = parseReady(msg.payload);
                        txnId = ready.txnId;
                        return true;
                    }
                    if (msg.type == MSG_ERROR) {
                        return false;
                    }
                }
            } finally {
                socket.setSoTimeout(oldTimeout);
            }
        } catch (IOException e) {
            return false;
        }
    }

    public void abort() {
        try {
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            // Ignore
        }
        connected = false;
    }

    public void close() {
        try {
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            // Ignore
        }
        connected = false;
    }

    public void setNetworkTimeout(int milliseconds) {
        this.networkTimeout = milliseconds;
        try {
            if (socket != null) {
                socket.setSoTimeout(milliseconds);
            }
        } catch (IOException e) {
            // Ignore
        }
    }

    public int getNetworkTimeout() {
        return networkTimeout;
    }

    public String getServerParameter(String name) {
        return serverParameters.get(name);
    }

    private void sendStartupMessage() throws IOException {
        Map<String, String> params = new LinkedHashMap<>();
        params.put("database", props.getDatabase() != null ? props.getDatabase() : "");
        params.put("user", props.getUser() != null ? props.getUser() : "");
        if (props.getApplicationName() != null) {
            params.put("application_name", props.getApplicationName());
        }

        long features = 0;
        if (props.isBinaryTransfer()) {
            features |= FEATURE_STREAMING;
        }

        byte[] payload = buildStartupPayload(features, params);
        sendMessage(MSG_STARTUP, payload, (byte) 0, true);
    }

    private void handleAuthentication() throws IOException, SQLException {
        while (true) {
            ProtocolMessage msg = readMessage();
            switch (msg.type) {
                case MSG_NEGOTIATE_VERSION:
                    continue;
                case MSG_AUTH_REQUEST: {
                    AuthRequest request = parseAuthRequest(msg.payload);
                    if (request.method == AUTH_OK) {
                        continue;
                    }
                    if (request.method == AUTH_PASSWORD) {
                        byte[] response = props.getPassword() != null
                            ? props.getPassword().getBytes(StandardCharsets.UTF_8) : new byte[0];
                        sendMessage(MSG_AUTH_RESPONSE, response, (byte) 0, true);
                        continue;
                    }
                    if (request.method == AUTH_SCRAM_SHA_256) {
                        if (scramClient == null) {
                            scramClient = new SBScramClient(props.getUser());
                        }
                        String clientFirst = scramClient.getClientFirstMessage();
                        sendMessage(MSG_AUTH_RESPONSE, clientFirst.getBytes(StandardCharsets.UTF_8), (byte) 0, true);
                        continue;
                    }
                    throw new SQLException("Unsupported authentication method", "28000");
                }
                case MSG_AUTH_CONTINUE: {
                    AuthContinue cont = parseAuthContinue(msg.payload);
                    if (cont.method != AUTH_SCRAM_SHA_256 || scramClient == null) {
                        throw new SQLException("Unsupported SCRAM continuation", "28000");
                    }
                    String clientFinal = scramClient.handleServerFirst(
                        new String(cont.data, StandardCharsets.UTF_8), props.getPassword());
                    sendMessage(MSG_AUTH_RESPONSE, clientFinal.getBytes(StandardCharsets.UTF_8), (byte) 0, true);
                    continue;
                }
                case MSG_AUTH_OK: {
                    AuthOk ok = parseAuthOk(msg.payload);
                    attachmentId = msg.attachmentId;
                    txnId = msg.txnId;
                    if (scramClient != null && ok.serverInfo.length > 0) {
                        String info = new String(ok.serverInfo, StandardCharsets.UTF_8);
                        if (info.startsWith("v=")) {
                            scramClient.verifyServerFinal(info);
                        }
                    }
                    continue;
                }
                case MSG_PARAMETER_STATUS: {
                    ParameterStatus status = parseParameterStatus(msg.payload);
                    serverParameters.put(status.name, status.value);
                    continue;
                }
                case MSG_READY: {
                    ReadyStatus ready = parseReady(msg.payload);
                    txnId = ready.txnId;
                    return;
                }
                case MSG_ERROR: {
                    ProtocolError error = parseErrorMessage(msg.payload);
                    throw new SQLException(buildErrorMessage(error), error.sqlState != null ? error.sqlState : "28000");
                }
                default:
                    continue;
            }
        }
    }

    private SBQueryResult readQueryResult() throws IOException, SQLException {
        SBQueryResult result = new SBQueryResult();
        List<SBColumnInfo> columns = new ArrayList<>();
        List<Object[]> rows = new ArrayList<>();
        long updateCount = -1;
        String commandTag = null;

        while (true) {
            ProtocolMessage msg = readMessage();
            switch (msg.type) {
                case MSG_ROW_DESCRIPTION:
                    columns = parseRowDescription(msg.payload);
                    result.setColumns(columns);
                    break;
                case MSG_DATA_ROW:
                    rows.add(parseDataRow(msg.payload, columns));
                    break;
                case MSG_COMMAND_COMPLETE: {
                    CommandComplete complete = parseCommandComplete(msg.payload);
                    commandTag = complete.tag;
                    updateCount = complete.rows;
                    break;
                }
                case MSG_PARAMETER_STATUS: {
                    ParameterStatus status = parseParameterStatus(msg.payload);
                    serverParameters.put(status.name, status.value);
                    break;
                }
                case MSG_READY: {
                    ReadyStatus ready = parseReady(msg.payload);
                    txnId = ready.txnId;
                    result.setRows(rows);
                    result.setCommandTag(commandTag);
                    if (updateCount >= 0) {
                        result.setUpdateCount(updateCount);
                    } else {
                        result.setUpdateCount(rows.size());
                    }
                    return result;
                }
                case MSG_ERROR: {
                    ProtocolError error = parseErrorMessage(msg.payload);
                    throw new SQLException(buildErrorMessage(error),
                        error.sqlState != null ? error.sqlState : "42000");
                }
                case MSG_NOTICE:
                case MSG_PARSE_COMPLETE:
                case MSG_BIND_COMPLETE:
                case MSG_CLOSE_COMPLETE:
                case MSG_NO_DATA:
                case MSG_PORTAL_SUSPENDED:
                case MSG_EMPTY_QUERY:
                case MSG_TXN_STATUS:
                case MSG_PONG:
                    break;
                default:
                    break;
            }
        }
    }

    private void sendSimpleQuery(String sql, int maxRows, int timeoutMs) throws IOException {
        int flags = props.isBinaryTransfer() ? QUERY_FLAG_BINARY_RESULT : 0;
        byte[] payload = buildQueryPayload(sql, flags, maxRows, timeoutMs);
        sendMessage(MSG_QUERY, payload, (byte) 0, false);
    }

    private void sendExtendedQuery(String sql, List<Object> params, List<Integer> paramTypes,
                                   int maxRows) throws IOException, SQLException {
        List<SBTypeCodec.ParamEncoding> encoded = new ArrayList<>();
        List<Integer> oids = new ArrayList<>();
        for (int i = 0; i < params.size(); i++) {
            Integer sqlType = (paramTypes != null && i < paramTypes.size()) ? paramTypes.get(i) : null;
            SBTypeCodec.ParamEncoding enc = SBTypeCodec.encodeParam(params.get(i), sqlType);
            encoded.add(enc);
            oids.add(enc.getOid());
        }

        byte[] parsePayload = buildParsePayload("", sql, oids);
        sendMessage(MSG_PARSE, parsePayload, (byte) 0, false);

        int[] resultFormats = props.isBinaryTransfer() ? new int[]{SBTypeCodec.FORMAT_BINARY} : new int[0];
        byte[] bindPayload = buildBindPayload("", "", encoded, resultFormats);
        sendMessage(MSG_BIND, bindPayload, (byte) 0, false);

        byte[] execPayload = buildExecutePayload("", maxRows);
        sendMessage(MSG_EXECUTE, execPayload, (byte) 0, false);
        sendMessage(MSG_SYNC, new byte[0], (byte) 0, false);
    }

    private byte[] buildStartupPayload(long features, Map<String, String> params) {
        byte[] paramBytes = buildParamList(params);
        ByteBuffer buf = ByteBuffer.allocate(2 + 2 + 8 + paramBytes.length).order(ByteOrder.LITTLE_ENDIAN);
        buf.put((byte) PROTOCOL_VERSION_MAJOR);
        buf.put((byte) PROTOCOL_VERSION_MINOR);
        buf.putShort((short) 0);
        buf.putLong(features);
        buf.put(paramBytes);
        return buf.array();
    }

    private byte[] buildParamList(Map<String, String> params) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            for (Map.Entry<String, String> entry : params.entrySet()) {
                out.write(entry.getKey().getBytes(StandardCharsets.UTF_8));
                out.write(0);
                out.write(entry.getValue().getBytes(StandardCharsets.UTF_8));
                out.write(0);
            }
            out.write(0);
        } catch (IOException e) {
            // ByteArrayOutputStream does not throw
        }
        return out.toByteArray();
    }

    private byte[] buildQueryPayload(String sql, int flags, int maxRows, int timeoutMs) {
        byte[] sqlBytes = sql.getBytes(StandardCharsets.UTF_8);
        ByteBuffer buf = ByteBuffer.allocate(12 + sqlBytes.length + 1).order(ByteOrder.LITTLE_ENDIAN);
        buf.putInt(flags);
        buf.putInt(maxRows);
        buf.putInt(timeoutMs);
        buf.put(sqlBytes);
        buf.put((byte) 0);
        return buf.array();
    }

    private byte[] buildParsePayload(String statementName, String sql, List<Integer> paramTypes) {
        byte[] nameBytes = statementName.getBytes(StandardCharsets.UTF_8);
        byte[] sqlBytes = sql.getBytes(StandardCharsets.UTF_8);
        int count = paramTypes != null ? paramTypes.size() : 0;
        int length = 4 + nameBytes.length + 4 + sqlBytes.length + 2 + 2 + (count * 4);
        ByteBuffer buf = ByteBuffer.allocate(length).order(ByteOrder.LITTLE_ENDIAN);
        buf.putInt(nameBytes.length);
        buf.put(nameBytes);
        buf.putInt(sqlBytes.length);
        buf.put(sqlBytes);
        buf.putShort((short) count);
        buf.putShort((short) 0);
        if (paramTypes != null) {
            for (int oid : paramTypes) {
                buf.putInt(oid);
            }
        }
        return buf.array();
    }

    private byte[] buildBindPayload(String portalName, String statementName,
                                    List<SBTypeCodec.ParamEncoding> params, int[] resultFormats) {
        byte[] portalBytes = portalName.getBytes(StandardCharsets.UTF_8);
        byte[] stmtBytes = statementName.getBytes(StandardCharsets.UTF_8);
        int paramCount = params != null ? params.size() : 0;

        int length = 4 + portalBytes.length + 4 + stmtBytes.length;
        length += 2 + (paramCount * 2);
        length += 2 + 2;
        for (SBTypeCodec.ParamEncoding param : params) {
            length += 4;
            if (!param.isNull() && param.getData() != null) {
                length += param.getData().length;
            }
        }
        length += 2 + (resultFormats != null ? resultFormats.length * 2 : 0);

        ByteBuffer buf = ByteBuffer.allocate(length).order(ByteOrder.LITTLE_ENDIAN);
        buf.putInt(portalBytes.length);
        buf.put(portalBytes);
        buf.putInt(stmtBytes.length);
        buf.put(stmtBytes);
        buf.putShort((short) paramCount);
        for (SBTypeCodec.ParamEncoding param : params) {
            buf.putShort((short) param.getFormat());
        }
        buf.putShort((short) paramCount);
        buf.putShort((short) 0);
        for (SBTypeCodec.ParamEncoding param : params) {
            if (param.isNull()) {
                buf.putInt(-1);
                continue;
            }
            byte[] data = param.getData() != null ? param.getData() : new byte[0];
            buf.putInt(data.length);
            buf.put(data);
        }
        if (resultFormats == null) {
            buf.putShort((short) 0);
        } else {
            buf.putShort((short) resultFormats.length);
            for (int fmt : resultFormats) {
                buf.putShort((short) fmt);
            }
        }
        return buf.array();
    }

    private byte[] buildExecutePayload(String portalName, int maxRows) {
        byte[] portalBytes = portalName.getBytes(StandardCharsets.UTF_8);
        ByteBuffer buf = ByteBuffer.allocate(4 + portalBytes.length + 4).order(ByteOrder.LITTLE_ENDIAN);
        buf.putInt(portalBytes.length);
        buf.put(portalBytes);
        buf.putInt(maxRows);
        return buf.array();
    }

    private byte[] buildCancelPayload(int cancelType, int targetSequence) {
        ByteBuffer buf = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN);
        buf.putInt(cancelType);
        buf.putInt(targetSequence);
        return buf.array();
    }

    private int sendMessage(byte type, byte[] payload, byte flags, boolean forceZero) throws IOException {
        int seq = sequence++;
        ByteBuffer buf = ByteBuffer.allocate(HEADER_SIZE + payload.length).order(ByteOrder.LITTLE_ENDIAN);
        buf.putInt(PROTOCOL_MAGIC);
        buf.put((byte) PROTOCOL_VERSION_MAJOR);
        buf.put((byte) PROTOCOL_VERSION_MINOR);
        buf.put(type);
        buf.put(flags);
        buf.putInt(payload.length);
        buf.putInt(seq);
        if (forceZero) {
            buf.put(new byte[16]);
            buf.putLong(0);
        } else {
            buf.put(attachmentId);
            buf.putLong(txnId);
        }
        buf.put(payload);
        outputStream.write(buf.array());
        outputStream.flush();
        return seq;
    }

    private ProtocolMessage readMessage() throws IOException {
        byte[] header = new byte[HEADER_SIZE];
        readFully(header);
        ByteBuffer buf = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN);
        int magic = buf.getInt();
        if (magic != PROTOCOL_MAGIC) {
            throw new IOException("Invalid protocol magic");
        }
        int major = buf.get() & 0xff;
        int minor = buf.get() & 0xff;
        if (major != PROTOCOL_VERSION_MAJOR || minor != PROTOCOL_VERSION_MINOR) {
            throw new IOException("Unsupported protocol version");
        }
        byte type = buf.get();
        byte flags = buf.get();
        int length = buf.getInt();
        if (length > MAX_MESSAGE_SIZE) {
            throw new IOException("Message too large");
        }
        int sequence = buf.getInt();
        byte[] attach = new byte[16];
        buf.get(attach);
        long txnId = buf.getLong();
        byte[] payload = new byte[length];
        if (length > 0) {
            readFully(payload);
        }
        return new ProtocolMessage(type, flags, length, sequence, attach, txnId, payload);
    }

    private void readFully(byte[] buffer) throws IOException {
        int offset = 0;
        while (offset < buffer.length) {
            int read = inputStream.read(buffer, offset, buffer.length - offset);
            if (read < 0) {
                throw new EOFException("Connection closed");
            }
            offset += read;
        }
    }

    private List<SBColumnInfo> parseRowDescription(byte[] payload) throws SQLException {
        ByteBuffer buf = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
        int count = Short.toUnsignedInt(buf.getShort());
        buf.getShort();
        List<SBColumnInfo> columns = new ArrayList<>(count);
        for (int i = 0; i < count; i++) {
            int nameLen = buf.getInt();
            byte[] nameBytes = new byte[nameLen];
            buf.get(nameBytes);
            String name = new String(nameBytes, StandardCharsets.UTF_8);
            int tableOid = buf.getInt();
            int columnIndex = Short.toUnsignedInt(buf.getShort());
            int typeOid = buf.getInt();
            short typeSize = buf.getShort();
            int typeModifier = buf.getInt();
            short format = (short) (buf.get() & 0xff);
            boolean nullable = buf.get() == 1;
            buf.getShort();

            SBColumnInfo col = new SBColumnInfo();
            col.setName(name);
            col.setTableOid(tableOid);
            col.setColumnNumber((short) columnIndex);
            col.setTypeOid(typeOid);
            col.setTypeSize(typeSize);
            col.setTypeModifier(typeModifier);
            col.setFormatCode(format);
            col.setNullable(nullable);
            columns.add(col);
        }
        return columns;
    }

    private Object[] parseDataRow(byte[] payload, List<SBColumnInfo> columns) throws SQLException {
        ByteBuffer buf = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
        int count = Short.toUnsignedInt(buf.getShort());
        int nullBytes = Short.toUnsignedInt(buf.getShort());
        byte[] nullBitmap = new byte[nullBytes];
        buf.get(nullBitmap);
        Object[] row = new Object[count];
        for (int i = 0; i < count; i++) {
            boolean isNull = false;
            if (nullBytes > 0) {
                isNull = (nullBitmap[i / 8] & (1 << (i % 8))) != 0;
            }
            if (isNull) {
                row[i] = null;
                continue;
            }
            int len = buf.getInt();
            if (len < 0) {
                row[i] = null;
                continue;
            }
            byte[] data = new byte[len];
            buf.get(data);
            SBColumnInfo col = columns.get(i);
            row[i] = SBTypeCodec.decodeValue(col.getTypeOid(), data, col.getFormatCode());
        }
        return row;
    }

    private CommandComplete parseCommandComplete(byte[] payload) {
        if (payload.length < 20) {
            return new CommandComplete(0, 0, "");
        }
        ByteBuffer buf = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
        buf.get();
        buf.get(new byte[3]);
        long rows = buf.getLong();
        long lastId = buf.getLong();
        byte[] tagBytes = new byte[payload.length - 20];
        buf.get(tagBytes);
        int nullIdx = -1;
        for (int i = 0; i < tagBytes.length; i++) {
            if (tagBytes[i] == 0) {
                nullIdx = i;
                break;
            }
        }
        String tag = nullIdx >= 0
            ? new String(tagBytes, 0, nullIdx, StandardCharsets.UTF_8)
            : new String(tagBytes, StandardCharsets.UTF_8);
        return new CommandComplete(rows, lastId, tag);
    }

    private ProtocolError parseErrorMessage(byte[] payload) {
        String severity = null;
        String sqlState = null;
        String message = null;
        String detail = null;
        String hint = null;
        int pos = 0;
        while (pos < payload.length) {
            byte field = payload[pos++];
            if (field == 0) {
                break;
            }
            int start = pos;
            while (pos < payload.length && payload[pos] != 0) {
                pos++;
            }
            if (pos >= payload.length) {
                break;
            }
            String value = new String(payload, start, pos - start, StandardCharsets.UTF_8);
            pos++;
            switch ((char) field) {
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
                default:
                    break;
            }
        }
        return new ProtocolError(severity, sqlState, message, detail, hint);
    }

    private String buildErrorMessage(ProtocolError error) {
        if (error == null) {
            return "query failed";
        }
        StringBuilder sb = new StringBuilder();
        if (error.message != null) {
            sb.append(error.message);
        }
        if (error.detail != null && !error.detail.isEmpty()) {
            if (sb.length() > 0) sb.append("\n");
            sb.append("DETAIL: ").append(error.detail);
        }
        if (error.hint != null && !error.hint.isEmpty()) {
            if (sb.length() > 0) sb.append("\n");
            sb.append("HINT: ").append(error.hint);
        }
        return sb.length() > 0 ? sb.toString() : "query failed";
    }

    private AuthRequest parseAuthRequest(byte[] payload) {
        if (payload.length < 4) {
            return new AuthRequest(AUTH_OK, new byte[0]);
        }
        int method = payload[0] & 0xff;
        byte[] data = Arrays.copyOfRange(payload, 4, payload.length);
        return new AuthRequest(method, data);
    }

    private AuthContinue parseAuthContinue(byte[] payload) {
        if (payload.length < 8) {
            return new AuthContinue(AUTH_OK, 0, new byte[0]);
        }
        int method = payload[0] & 0xff;
        int stage = payload[1] & 0xff;
        int dataLen = ByteBuffer.wrap(payload, 4, 4).order(ByteOrder.LITTLE_ENDIAN).getInt();
        int end = Math.min(payload.length, 8 + dataLen);
        byte[] data = Arrays.copyOfRange(payload, 8, end);
        return new AuthContinue(method, stage, data);
    }

    private AuthOk parseAuthOk(byte[] payload) {
        if (payload.length < 20) {
            return new AuthOk(new byte[16], new byte[0]);
        }
        byte[] sessionId = Arrays.copyOfRange(payload, 0, 16);
        int infoLen = ByteBuffer.wrap(payload, 16, 4).order(ByteOrder.LITTLE_ENDIAN).getInt();
        int end = Math.min(payload.length, 20 + infoLen);
        byte[] serverInfo = Arrays.copyOfRange(payload, 20, end);
        return new AuthOk(sessionId, serverInfo);
    }

    private ParameterStatus parseParameterStatus(byte[] payload) {
        if (payload.length < 8) {
            return new ParameterStatus("", "");
        }
        ByteBuffer buf = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
        int nameLen = buf.getInt();
        byte[] nameBytes = new byte[nameLen];
        buf.get(nameBytes);
        int valueLen = buf.getInt();
        byte[] valueBytes = new byte[valueLen];
        buf.get(valueBytes);
        return new ParameterStatus(new String(nameBytes, StandardCharsets.UTF_8),
            new String(valueBytes, StandardCharsets.UTF_8));
    }

    private ReadyStatus parseReady(byte[] payload) {
        if (payload.length < 20) {
            return new ReadyStatus((byte) 0, 0, 0);
        }
        ByteBuffer buf = ByteBuffer.wrap(payload).order(ByteOrder.LITTLE_ENDIAN);
        byte status = buf.get();
        buf.get(new byte[3]);
        long txn = buf.getLong();
        long visibility = buf.getLong();
        return new ReadyStatus(status, txn, visibility);
    }

    private void upgradeToSSL(String sslMode) throws IOException, SQLException {
        SSLSocketFactory factory = createSslContext().getSocketFactory();
        SSLSocket sslSocket = (SSLSocket) factory.createSocket(socket, props.getHost(), props.getPort(), true);
        if ("verify-full".equalsIgnoreCase(sslMode)) {
            SSLParameters params = sslSocket.getSSLParameters();
            params.setEndpointIdentificationAlgorithm("HTTPS");
            sslSocket.setSSLParameters(params);
        }
        sslSocket.startHandshake();
        if (props.getSocketTimeout() > 0) {
            sslSocket.setSoTimeout(props.getSocketTimeout() * 1000);
        }

        socket = sslSocket;
        inputStream = new BufferedInputStream(socket.getInputStream(), 65536);
        outputStream = new BufferedOutputStream(socket.getOutputStream(), 65536);
    }

    private SSLContext createSslContext() throws SQLException {
        try {
            KeyManager[] keyManagers = null;
            TrustManager[] trustManagers = null;

            if (props.getSslRootCert() != null) {
                trustManagers = buildTrustManagers(props.getSslRootCert());
            }

            if (props.getSslCert() != null) {
                keyManagers = buildKeyManagers(props.getSslCert(), props.getSslPassword());
            }

            SSLContext context = SSLContext.getInstance("TLS");
            context.init(keyManagers, trustManagers, null);
            return context;
        } catch (Exception e) {
            throw new SQLException("Failed to initialize SSL context: " + e.getMessage(), "08001", e);
        }
    }

    private TrustManager[] buildTrustManagers(String caPath) throws Exception {
        java.security.cert.CertificateFactory cf =
            java.security.cert.CertificateFactory.getInstance("X.509");
        java.security.cert.Certificate cert;
        try (InputStream in = new FileInputStream(caPath)) {
            cert = cf.generateCertificate(in);
        }
        KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
        trustStore.load(null, null);
        trustStore.setCertificateEntry("ca", cert);
        TrustManagerFactory tmf =
            TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(trustStore);
        return tmf.getTrustManagers();
    }

    private KeyManager[] buildKeyManagers(String keystorePath, String password) throws Exception {
        String lower = keystorePath.toLowerCase();
        String type = (lower.endsWith(".p12") || lower.endsWith(".pfx")) ? "PKCS12" : "JKS";
        KeyStore keyStore = KeyStore.getInstance(type);
        char[] pass = password != null ? password.toCharArray() : new char[0];
        try (InputStream in = new FileInputStream(keystorePath)) {
            keyStore.load(in, pass);
        }
        KeyManagerFactory kmf =
            KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(keyStore, pass);
        return kmf.getKeyManagers();
    }

    private static final class ProtocolMessage {
        final byte type;
        final byte flags;
        final int length;
        final int sequence;
        final byte[] attachmentId;
        final long txnId;
        final byte[] payload;

        ProtocolMessage(byte type, byte flags, int length, int sequence,
                        byte[] attachmentId, long txnId, byte[] payload) {
            this.type = type;
            this.flags = flags;
            this.length = length;
            this.sequence = sequence;
            this.attachmentId = attachmentId;
            this.txnId = txnId;
            this.payload = payload;
        }
    }

    private static final class AuthRequest {
        final int method;
        final byte[] data;

        AuthRequest(int method, byte[] data) {
            this.method = method;
            this.data = data;
        }
    }

    private static final class AuthContinue {
        final int method;
        final int stage;
        final byte[] data;

        AuthContinue(int method, int stage, byte[] data) {
            this.method = method;
            this.stage = stage;
            this.data = data;
        }
    }

    private static final class AuthOk {
        final byte[] sessionId;
        final byte[] serverInfo;

        AuthOk(byte[] sessionId, byte[] serverInfo) {
            this.sessionId = sessionId;
            this.serverInfo = serverInfo;
        }
    }

    private static final class ParameterStatus {
        final String name;
        final String value;

        ParameterStatus(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }

    private static final class ReadyStatus {
        final byte status;
        final long txnId;
        final long visibility;

        ReadyStatus(byte status, long txnId, long visibility) {
            this.status = status;
            this.txnId = txnId;
            this.visibility = visibility;
        }
    }

    private static final class CommandComplete {
        final long rows;
        final long lastId;
        final String tag;

        CommandComplete(long rows, long lastId, String tag) {
            this.rows = rows;
            this.lastId = lastId;
            this.tag = tag;
        }
    }

    private static final class ProtocolError {
        final String severity;
        final String sqlState;
        final String message;
        final String detail;
        final String hint;

        ProtocolError(String severity, String sqlState, String message, String detail, String hint) {
            this.severity = severity;
            this.sqlState = sqlState;
            this.message = message;
            this.detail = detail;
            this.hint = hint;
        }
    }
}
